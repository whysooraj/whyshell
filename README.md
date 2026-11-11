# whyShell

whyShell is an opinionated, hardware-accelerated Wayland desktop shell built on Hyprland, Quickshell, and Qt6, crafted with macOS Sonoma and Tahoe liquid glass aesthetics.

## Showcase

- Unified TopBar with active application menus, battery, audio, and control center toggles.
- Liquid glass Dock with smooth magnification, running indicators, and minimized window thumbnails.
- Authentic macOS Sonoma lock screen with bold rounded typography, drop shadows, frosted glass password pill, and full customization via System Settings or CLI.
- Native Qt6 System Settings app (`~/.local/bin/systemsettings`) with direct reactive configuration.
- Spotlight launcher (`Super + Space`) and full-screen Launchpad.

## Repository Layout

| Path | Target | Description |
|------|--------|-------------|
| `hypr/` | `~/.config/hypr` | Hyprland compositor configuration, keybinds, and scripts |
| `quickshell/` | `~/.config/quickshell` | Quickshell modules (macos, ii, lucid, etc.) |
| `SystemSettings/` | built -> `~/.local/bin/systemsettings` | Native Qt6 macOS-style System Settings app |
| `wallpapers/` | `~/Pictures/Wallpapers` | Bundled wallpapers (Sonoma, Sequoia, M3) |
| `rofi/` | `~/.config/rofi` | Window switcher and application launcher theme |
| `kitty/` | `~/.config/kitty` | Terminal emulator configuration with SF Mono fonts |
| `install.sh` | `./install.sh` | Automated installer script |

## Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/whysooraj/whyshell.git ~/.local/share/whyshell/src
cd ~/.local/share/whyshell/src
./install.sh
```

### Building System Settings Manually

```bash
cd SystemSettings
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
install -m755 build/systemsettings ~/.local/bin/systemsettings
```

### Lock Screen Customization CLI

Configure your lock screen directly from terminal:

```bash
whyshell-lock-config --status
whyshell-lock-config --wallpaper sonoma-light
whyshell-lock-config --clock 12h
whyshell-lock-config --dim 0.12
whyshell-lock-config --reset
```

Or configure it visually in System Settings -> Lock Screen.

## Author

Created and maintained by whysooraj.
