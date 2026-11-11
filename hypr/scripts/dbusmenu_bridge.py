#!/usr/bin/env python3
"""
whyshell DBus Global Menu Bridge
Implements com.canonical.AppMenu.Registrar and bridges application dbusmenu
structures to JSON for whyShell TopBar.
"""

import sys
import os
import json
import time
import subprocess
import threading
import signal
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

REGISTRAR_IFACE = "com.canonical.AppMenu.Registrar"
REGISTRAR_PATH = "/com/canonical/AppMenu/Registrar"
DBUSMENU_IFACE = "com.canonical.dbusmenu"
OUTPUT_FILE = "/tmp/whyshell_dbusmenu.json"
CMD_FILE = "/tmp/whyshell_menu_cmd"

class AppMenuRegistrar(dbus.service.Object):
    def __init__(self, bus, path):
        super().__init__(bus, path)
        self.bus = bus
        self.windows = {}  # win_id -> {service, path, pid}
        self.services = {} # service -> win_id
        self.active_win_id = None
        self.active_service = None
        self.active_path = None
        self.lock = threading.Lock()

    @dbus.service.method(REGISTRAR_IFACE, in_signature="uo", sender_keyword="sender")
    def RegisterWindow(self, window_id, menu_path, sender=None):
        win_id = int(window_id)
        m_path = str(menu_path)
        sender_str = str(sender)

        # Get process PID of caller if possible
        pid = 0
        try:
            dbus_obj = self.bus.get_object("org.freedesktop.DBus", "/org/freedesktop/DBus")
            dbus_iface = dbus.Interface(dbus_obj, "org.freedesktop.DBus")
            pid = int(dbus_iface.GetConnectionUnixProcessID(sender_str))
        except Exception:
            pass

        with self.lock:
            self.windows[win_id] = {
                "service": sender_str,
                "path": m_path,
                "pid": pid,
            }
            self.services[sender_str] = win_id

        self.WindowRegistered(win_id, sender_str, m_path)
        self.update_active_menu()

    @dbus.service.method(REGISTRAR_IFACE, in_signature="u")
    def UnregisterWindow(self, window_id):
        win_id = int(window_id)
        with self.lock:
            info = self.windows.pop(win_id, None)
            if info and info["service"] in self.services:
                del self.services[info["service"]]
        self.WindowUnregistered(win_id)
        self.update_active_menu()

    @dbus.service.method(REGISTRAR_IFACE, in_signature="u", out_signature="so")
    def GetMenuForWindow(self, window_id):
        win_id = int(window_id)
        with self.lock:
            if win_id in self.windows:
                return (self.windows[win_id]["service"], self.windows[win_id]["path"])
        return ("", "/")

    @dbus.service.method(REGISTRAR_IFACE, out_signature="a(uso)")
    def GetMenus(self):
        with self.lock:
            return [(wid, info["service"], info["path"]) for wid, info in self.windows.items()]

    @dbus.service.signal(REGISTRAR_IFACE, signature="uso")
    def WindowRegistered(self, window_id, service, menu_path):
        pass

    @dbus.service.signal(REGISTRAR_IFACE, signature="u")
    def WindowUnregistered(self, window_id):
        pass

    def on_name_owner_changed(self, name, old_owner, new_owner):
        if not new_owner and name in self.services:
            win_id = self.services.get(name)
            if win_id is not None:
                self.UnregisterWindow(win_id)

    def trigger_item(self, item_id):
        with self.lock:
            srv = self.active_service
            pth = self.active_path

        if not srv or not pth:
            return False

        try:
            obj = self.bus.get_object(srv, pth)
            iface = dbus.Interface(obj, DBUSMENU_IFACE)
            ts = dbus.UInt32(int(time.time()))
            iface.Event(dbus.Int32(item_id), "clicked", dbus.UInt32(0), ts)
            return True
        except Exception as e:
            print(f"[dbusmenu_bridge] Click event failed: {e}", file=sys.stderr)
            return False

    def update_active_menu(self):
        active_pid = 0
        active_class = ""
        try:
            res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True, timeout=1)
            if res.returncode == 0 and res.stdout.strip():
                data = json.loads(res.stdout)
                active_pid = data.get("pid", 0)
                active_class = data.get("class", "").lower()
        except Exception:
            pass

        target = None
        with self.lock:
            if active_pid:
                for wid, info in self.windows.items():
                    if info.get("pid") == active_pid:
                        target = info
                        break

            # Fallback: if single window registered
            if not target and len(self.windows) == 1:
                target = list(self.windows.values())[0]

            if target:
                self.active_service = target["service"]
                self.active_path = target["path"]
            else:
                self.active_service = None
                self.active_path = None

        if not target:
            self._write_empty_menu()
            return

        try:
            obj = self.bus.get_object(target["service"], target["path"])
            iface = dbus.Interface(obj, DBUSMENU_IFACE)
            _, root_layout = iface.GetLayout(
                dbus.Int32(0),
                dbus.Int32(2),
                dbus.Array(["label", "enabled", "visible", "type", "shortcut", "children-display"], signature="s")
            )
            parsed = self._parse_layout(root_layout, target["service"], target["path"])
            self._write_json(parsed)
        except Exception as e:
            self._write_empty_menu()

    def _parse_layout(self, root_layout, service, path):
        # root_layout: (id, properties, children)
        _, _, top_children = root_layout
        top_menus = []
        menus_dict = {}

        for child in top_children:
            cid, cprops, cchildren = child
            raw_label = str(cprops.get("label", "")).replace("_", "").strip()
            if not raw_label:
                continue

            menu_key = raw_label.lower()
            top_menus.append(raw_label)

            items = []
            for item in cchildren:
                iid, iprops, _ = item
                is_sep = str(iprops.get("type", "")) == "separator"
                label = str(iprops.get("label", "")).replace("_", "")
                enabled = bool(iprops.get("enabled", True))
                
                # Shortcut parsing
                shortcut_str = ""
                raw_sc = iprops.get("shortcut")
                if raw_sc and isinstance(raw_sc, (list, dbus.Array)):
                    try:
                        combo = raw_sc[0]
                        parts = [str(x).capitalize() for x in combo]
                        shortcut_str = "+".join(parts)
                    except Exception:
                        pass

                items.append({
                    "id": int(iid),
                    "label": label,
                    "sub": shortcut_str,
                    "enabled": enabled,
                    "sep": is_sep
                })

            menus_dict[menu_key] = items

        return {
            "has_menu": len(top_menus) > 0,
            "service": service,
            "path": path,
            "top_menus": top_menus,
            "menus": menus_dict
        }

    def _write_empty_menu(self):
        self._write_json({"has_menu": False, "top_menus": [], "menus": {}})

    def _write_json(self, data):
        tmp_path = OUTPUT_FILE + ".tmp"
        try:
            with open(tmp_path, "w") as f:
                json.dump(data, f)
            os.replace(tmp_path, OUTPUT_FILE)
        except Exception as e:
            pass


def command_watcher(registrar):
    while True:
        try:
            if os.path.exists(CMD_FILE):
                with open(CMD_FILE, "r") as f:
                    content = f.read().strip()
                try:
                    os.remove(CMD_FILE)
                except Exception:
                    pass

                if content.startswith("click "):
                    try:
                        item_id = int(content.split(" ")[1])
                        registrar.trigger_item(item_id)
                    except Exception:
                        pass
        except Exception:
            pass
        time.sleep(0.05)


def hyprland_poller(registrar):
    last_window = ""
    while True:
        try:
            res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True, timeout=1)
            if res.returncode == 0:
                cur = res.stdout.strip()
                if cur != last_window:
                    last_window = cur
                    registrar.update_active_menu()
        except Exception:
            pass
        time.sleep(0.3)


def main():
    if "--click" in sys.argv:
        idx = sys.argv.index("--click")
        if idx + 1 < len(sys.argv):
            item_id = sys.argv[idx + 1]
            with open(CMD_FILE, "w") as f:
                f.write(f"click {item_id}\n")
            sys.exit(0)

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()

    try:
        bus_name = dbus.service.BusName(REGISTRAR_IFACE, bus, do_not_queue=True)
    except dbus.exceptions.NameExistsException:
        print("[dbusmenu_bridge] Service already running.")
        sys.exit(0)

    registrar = AppMenuRegistrar(bus, REGISTRAR_PATH)
    bus.add_signal_receiver(
        registrar.on_name_owner_changed,
        signal_name="NameOwnerChanged",
        dbus_interface="org.freedesktop.DBus"
    )

    t_cmd = threading.Thread(target=command_watcher, args=(registrar,), daemon=True)
    t_cmd.start()

    t_hypr = threading.Thread(target=hyprland_poller, args=(registrar,), daemon=True)
    t_hypr.start()

    # Initial state
    registrar._write_empty_menu()

    loop = GLib.MainLoop()
    signal.signal(signal.SIGINT, lambda *_: loop.quit())
    signal.signal(signal.SIGTERM, lambda *_: loop.quit())
    loop.run()


if __name__ == "__main__":
    main()
