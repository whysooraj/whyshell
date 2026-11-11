import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtMultimedia
import ".."
import "../Pages.js" as Pages

Column {
    id: page

    property string pageId: "wallpaper"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0

    function eget(k, d) { bumpU; bumpE; return Shell.eget(k, d) }
    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }

    width: parent ? parent.width : 640
    spacing: 12

    // ---------------------------------------------------------------- library
    property var allImgs: []
    property var dyn: []
    property var folderList: []
    property var sections: []

    function refreshFolders() {
        var roots = [
            HOME_DIR + "/Pictures/wallpapers",
            HOME_DIR + "/Pictures/Wallpapers",
            HOME_DIR + "/.config/wallpapers",
            HOME_DIR + "/.local/share/wallpapers/MacTahoe/contents/images",
            HOME_DIR + "/.local/share/wallpapers/MacTahoe-Dark/contents/images",
            HOME_DIR + "/.local/share/wallpapers/MacTahoe-Light/contents/images",
            HOME_DIR + "/.local/share/equora/wallpapers",
            HOME_DIR + "/Pictures"
        ]

        var currentF = decodeURIComponent(String(eget("wallpaper.folder", "")).replace(/^file:\/\//, "")).replace(/\/+$/, "")
        if (currentF.length > 0)
            roots.unshift(currentF)

        var custom = eget("wallpaper.customFolders", [])
        if (Array.isArray(custom)) {
            for (var c = 0; c < custom.length; c++) {
                if (custom[c]) {
                    var cp = decodeURIComponent(String(custom[c]).replace(/^file:\/\//, "")).replace(/\/+$/, "")
                    if (cp.length > 0)
                        roots.unshift(cp)
                }
            }
        }

        var out = []
        var seen = {}
        for (var i = 0; i < roots.length; i++) {
            var r = roots[i]
            if (!r || seen[r])
                continue
            seen[r] = true
            var files = Shell.listFiles(r, "")
            if (files.length > 0) {
                var folderName = r.split("/").filter(Boolean).pop() || r
                out.push({ name: folderName, dir: r, count: files.length })
            }
        }
        folderList = out
    }

    function addCustomFolder(folderUri) {
        if (!folderUri)
            return
        var d = decodeURIComponent(folderUri.toString().replace(/^file:\/\//, "")).replace(/\/+$/, "")
        if (d.length === 0)
            return

        var custom = eget("wallpaper.customFolders", [])
        if (!Array.isArray(custom)) {
            custom = (custom && custom.length > 0) ? [custom.toString()] : []
        }
        var found = false
        for (var i = 0; i < custom.length; i++) {
            if (custom[i] === d) {
                found = true
                break
            }
        }
        if (!found) {
            custom.push(d)
            Shell.eset("wallpaper.customFolders", custom)
        }
        Shell.eset("wallpaper.folder", "file://" + d + "/")
        rev++
        build()
    }

    function build() {
        refreshFolders()

        var activeFolder = decodeURIComponent(String(eget("wallpaper.folder", "")).replace(/^file:\/\//, "")).replace(/\/+$/, "")
        if (activeFolder.length === 0 && folderList.length > 0)
            activeFolder = folderList[0].dir

        var s = []
        var seenDirs = {}
        var allScanned = []

        // 1. First section: Active / Selected Wallpaper folder
        if (activeFolder.length > 0) {
            var activeImgs = Shell.listImages(activeFolder)
            if (activeImgs.length > 0) {
                seenDirs[activeFolder] = true
                var activeName = activeFolder.split("/").filter(Boolean).pop() || "Wallpapers"
                s.push({
                    title: activeName,
                    dir: activeFolder,
                    files: activeImgs,
                    add: true,
                    hint: "No images found in " + activeName
                })
                for (var ai = 0; ai < activeImgs.length; ai++)
                    allScanned.push(activeImgs[ai])
            }
        }

        // 2. Custom Folders added by user
        var custom = eget("wallpaper.customFolders", [])
        if (Array.isArray(custom)) {
            for (var c = 0; c < custom.length; c++) {
                var cDir = decodeURIComponent(String(custom[c]).replace(/^file:\/\//, "")).replace(/\/+$/, "")
                if (cDir.length > 0 && !seenDirs[cDir]) {
                    seenDirs[cDir] = true
                    var cImgs = Shell.listImages(cDir)
                    var cName = cDir.split("/").filter(Boolean).pop() || cDir
                    s.push({
                        title: cName,
                        dir: cDir,
                        files: cImgs,
                        add: true,
                        hint: "No images found in " + cName
                    })
                    for (var ci = 0; ci < cImgs.length; ci++)
                        allScanned.push(cImgs[ci])
                }
            }
        }

        // 3. Known wallpaper folders (e.g. Pictures/wallpapers, Pictures/Wallpapers)
        var wellKnown = [
            HOME_DIR + "/Pictures/wallpapers",
            HOME_DIR + "/Pictures/Wallpapers",
            HOME_DIR + "/.config/wallpapers"
        ]
        for (var w = 0; w < wellKnown.length; w++) {
            var wkDir = wellKnown[w]
            if (!seenDirs[wkDir]) {
                var wkImgs = Shell.listImages(wkDir)
                if (wkImgs.length > 0) {
                    seenDirs[wkDir] = true
                    var wkName = wkDir.split("/").filter(Boolean).pop() || wkDir
                    s.push({
                        title: wkName,
                        dir: wkDir,
                        files: wkImgs,
                        add: true,
                        hint: ""
                    })
                    for (var wi = 0; wi < wkImgs.length; wi++)
                        allScanned.push(wkImgs[wi])
                }
            }
        }

        // 4. macOS Tahoe System Wallpapers
        var macTahoe = [
            HOME_DIR + "/.local/share/wallpapers/MacTahoe/contents/images",
            HOME_DIR + "/.local/share/wallpapers/MacTahoe-Dark/contents/images",
            HOME_DIR + "/.local/share/wallpapers/MacTahoe-Light/contents/images"
        ]
        var macImgs = []
        for (var m = 0; m < macTahoe.length; m++) {
            var mtImgs = Shell.listImages(macTahoe[m])
            for (var mi = 0; mi < mtImgs.length; mi++)
                macImgs.push(mtImgs[mi])
        }
        if (macImgs.length > 0) {
            s.push({
                title: "macOS Tahoe",
                dir: macTahoe[0],
                files: macImgs,
                add: false,
                hint: ""
            })
            for (var mti = 0; mti < macImgs.length; mti++)
                allScanned.push(macImgs[mti])
        }

        // 5. Dynamic wallpapers (GIFs / Videos from any scanned folders)
        var dynImgs = []
        for (var si = 0; si < s.length; si++) {
            for (var fi = 0; fi < s[si].files.length; fi++) {
                var fItem = s[si].files[fi]
                if (fItem.animated === true || isGif(fItem.path) || isVideo(fItem.path)) {
                    dynImgs.push(fItem)
                }
            }
        }
        if (dynImgs.length > 0) {
            s.unshift({
                title: "Dynamic Wallpapers",
                dir: "",
                files: dynImgs,
                add: false,
                hint: "Dynamic wallpapers (GIF, video) appear here."
            })
        }

        allImgs = allScanned
        dyn = dynImgs
        sections = s

        console.log("WALLPAPER_LIB sections=" + sections.length + " activeFolder=" + activeFolder)
        for (var si = 0; si < sections.length; si++)
            console.log("  SECTION " + si + ": " + sections[si].title + " (" + sections[si].files.length + ")")
    }

    readonly property string current: {
        bumpU
        bumpE
        var p = String(uget("wallpaperPath", ""))
        if (p.length > 0)
            return p
        p = String(eget("wallpaper.path", ""))
        if (p.length > 0)
            return p
        var active = Shell.execOut("awww query 2>/dev/null | grep -o '/.*' | head -n1", 500)
        if (active && active.length > 0)
            return active.trim()
        if (allImgs.length > 0)
            return allImgs[0].path
        return ""
    }

    function apply(path) {
        if (!path) return
        Shell.uset("wallpaperPath", path)
        Shell.eset("wallpaper.path", path)
        Shell.eset("wallpaper.folder", "file://" + path.split("/").slice(0, -1).join("/") + "/")
        Shell.run("pgrep -x awww-daemon >/dev/null || awww-daemon & sleep 0.2; awww img --transition-type center --transition-step 90 '" + path.replace(/'/g, "'\\''") + "'")
        Shell.run("bash " + HOME_DIR + "/.config/revo/hypr/scripts/wallpapers/set.sh '" + path.replace(/'/g, "'\\''") + "'")
        rev++
    }

    function applyColor(c) {
        Shell.uset("wallpaperPath", "")
        Shell.eset("wallpaper.color", c)
        Shell.eset("wallpaper.path", "")
        Shell.run("magick -size 1920x1080 xc:'" + c + "' /tmp/solid_wall.png && pgrep -x awww-daemon >/dev/null || awww-daemon & sleep 0.2; awww img --transition-type center /tmp/solid_wall.png")
        rev++
    }

    function isVideo(p) {
        var e = p.toLowerCase().split("?")[0]
        return e.endsWith(".mp4") || e.endsWith(".webm") || e.endsWith(".mkv") || e.endsWith(".mov")
    }
    function isGif(p) { return p.toLowerCase().split("?")[0].endsWith(".gif") }
    function nameOf(p) { return p.split("/").pop().replace(/\.[^.]+$/, "").replace(/[-_]/g, " ") }

    function modeOf() { return String(eget("wallpaper.mode", "Still")) }

    Component.onCompleted: {
        build()
        if (Shell.eget("wallpaper.mode", "").toString().length === 0)
            Shell.eset("wallpaper.mode", "Still")
    }

    FileDialog {
        id: addPhotoDlg
        title: "Choose Wallpaper"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.jpg *.jpeg *.png *.webp *.bmp *.gif *.JPG)",
                      "Movies (*.mp4 *.webm *.mov *.mkv)", "All files (*)"]
        onAccepted: {
            var p = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""))
            page.apply(p)
        }
    }

    FolderDialog {
        id: addFolderDlg
        title: "Choose Wallpaper Folder"
        onAccepted: {
            page.addCustomFolder(selectedFolder.toString())
        }
    }

    Placard {
        iconFile: "sb_wallpaper"
        title: "Wallpaper"
    }

    // ---------------------------------------------------------------- preview
    Item {
        width: parent.width
        height: Math.round(width * 0.44)

        Rectangle {
            id: frame
            anchors.fill: parent
            radius: 12
            color: Theme.dark ? "#101014" : "#e8eaef"
            border.width: 1
            border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.12)
            clip: true
        }

        Rectangle {
            anchors.fill: frame
            color: eget("wallpaper.color", "#6967b0")
            opacity: preview.status === Image.Ready || preview.active ? 0
                     : (stillPreview.status === Image.Ready && stillPreview.visible ? 0 : 1)
            Behavior on opacity { NumberAnimation { duration: 260 } }
            HueGradient { anchors.fill: parent }
        }

        AnimatedImage {
            id: preview
            property bool active: page.current.length > 0 && page.isGif(page.current)
            anchors.fill: frame
            anchors.margins: 1
            source: active ? "file://" + page.current : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: active && status === Image.Ready
            playing: visible
        }

        Video {
            id: vidPreview
            property bool active: page.current.length > 0 && page.isVideo(page.current)
            anchors.fill: frame
            anchors.margins: 1
            source: active ? "file://" + page.current : ""
            fillMode: VideoOutput.PreserveAspectCrop
            visible: active && playbackState === MediaPlayer.PlayingState
            loops: MediaPlayer.Infinite
            autoPlay: active
            muted: true
        }

        Image {
            id: stillPreview
            property bool active: page.current.length > 0 && !page.isGif(page.current) && !page.isVideo(page.current)
            anchors.fill: frame
            anchors.margins: 1
            source: active ? "file://" + page.current : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: active && status === Image.Ready
        }

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 12
            width: nameText.implicitWidth + 20
            height: 24
            radius: 12
            color: Qt.rgba(0, 0, 0, 0.55)

            Text {
                id: nameText
                anchors.centerIn: parent
                text: page.current.length > 0 ? page.nameOf(page.current) : "Choose a Wallpaper"
                font.family: Theme.fontText
                font.pixelSize: 12
                color: "white"
            }
        }
    }

    // ---------------------------------------------------------------- options
    // ---------------------------------------------------------------- options
    SectionHeader { text: "Mode" }

    GroupCard {
        Column {
            id: modeCol
            x: 14
            y: 12
            width: parent.width - 28
            spacing: 8

            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: [
                        { label: "Dynamic", glyph: "\u25D1" },
                        { label: "Still", glyph: "\u25AD" },
                        { label: "Shuffle", glyph: "\u21C4" },
                        { label: "Video", glyph: "\u25B6" }
                    ]

                    delegate: Rectangle {
                        id: mode
                        required property var modelData
                        width: modeLbl.implicitWidth + 24
                        height: 34
                        radius: 7
                        color: page.modeOf() === mode.modelData.label ? Theme.accent
                             : Theme.dark ? "#3A3A3C" : "#E9E9EB"
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.06)

                        Text {
                            id: modeLbl
                            anchors.centerIn: parent
                            text: mode.modelData.glyph + "  " + mode.modelData.label
                            font { family: Theme.fontText; pixelSize: 12 }
                            color: page.modeOf() === mode.modelData.label ? "white" : Theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Shell.eset("wallpaper.mode", mode.modelData.label)
                                rev++
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 4 }
        }
    }

    SectionHeader { text: "Colours" }

    GroupCard {
        Column {
            id: colorCol
            x: 14
            y: 12
            width: parent.width - 28
            spacing: 8

            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: {
                        var c = eget("wallpaper.colors", [])
                        var out = []
                        for (var i = 0; i < c.length; i++) {
                            var v = String(c[i])
                            if (v === "add" || v.charAt(0) !== "#")
                                continue
                            out.push(v)
                        }
                        if (out.length === 0)
                            out = ["#000000", "#1C1C1E", "#6967B0", "#3E7CB1", "#2AC3DE", "#FF6B8B", "#8AB17D", "#D9A441", "#C46A6A", "#7AA2F7"]
                        return out
                    }

                    delegate: Rectangle {
                        id: swatch
                        required property var modelData
                        width: 32
                        height: 32
                        radius: 16
                        color: modelData
                        border.width: 2.5
                        border.color: String(eget("wallpaper.path", "")).length === 0
                                      && String(eget("wallpaper.color", "")) === modelData
                                      ? Theme.accent : Qt.rgba(1, 1, 1, 0.25)

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.applyColor(swatch.modelData)
                        }
                    }
                }
            }

            Item { width: 1; height: 4 }
        }
    }

    GroupCard {
        DetailRow {
            title: "Show on all Spaces"
            showSwitch: true
            switchOn: eget("wallpaper.allSpaces", true) === true
            onToggled: (c) => { Shell.eset("wallpaper.allSpaces", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show colour on desktop"
            showSwitch: true
            switchOn: eget("wallpaper.desktopEnable", true) === true
            onToggled: (c) => { Shell.eset("wallpaper.desktopEnable", c); Shell.eset("desktopEnable", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Folder"
            pickerOptions: page.folderList.map(function (f) { return f.name })
            value: {
                page.rev
                var cur = decodeURIComponent(String(page.eget("wallpaper.folder", "")).replace(/^file:\/\//, "")).replace(/\/+$/, "")
                for (var i = 0; i < page.folderList.length; i++) {
                    if (page.folderList[i].dir === cur)
                        return page.folderList[i].name
                }
                return page.folderList.length > 0 ? page.folderList[0].name : "\u2014"
            }
            onPicked: (v) => {
                for (var i = 0; i < page.folderList.length; i++) {
                    if (page.folderList[i].name === v) {
                        Shell.eset("wallpaper.folder", "file://" + page.folderList[i].dir + "/")
                        page.rev++
                        page.build()
                        break
                    }
                }
            }
        }
    }

    Row {
        x: 12
        width: parent.width - 24
        spacing: 8

        MacButton {
            text: "Add Photo\u2026"
            primary: true
            onClicked: addPhotoDlg.open()
        }
        MacButton {
            text: "Add Folder\u2026"
            onClicked: addFolderDlg.open()
        }
    }

    // ---------------------------------------------------------------- strips
    Repeater {
        model: page.sections

        delegate: Column {
            id: sec
            required property var modelData
            required property int index
            width: page.width
            spacing: 8

            Item { width: 1; height: 6 }

            SectionHeader {
                id: secHeader
                width: parent.width
                text: sec.modelData.title
                suffix: " (" + sec.modelData.files.length + ")"
                buttonLabel: sec.modelData.add ? "Add Photo\u2026" : ""
                onButtonClicked: {
                    if (sec.modelData.dir) {
                        addPhotoDlg.currentFolder = "file://" + sec.modelData.dir
                    }
                    addPhotoDlg.open()
                }
            }

            Rectangle {
                id: cardRect
                x: 12
                width: parent.width - 24
                height: sec.modelData.files.length > 0 ? 120 : 54
                implicitHeight: height
                radius: 10
                color: Theme.cardBg
                clip: true

                Text {
                    visible: sec.modelData.files.length === 0
                    anchors.centerIn: parent
                    width: parent.width - 32
                    horizontalAlignment: Text.AlignHCenter
                    text: sec.modelData.hint && sec.modelData.hint.length > 0 ? sec.modelData.hint : "No wallpapers found."
                    font { family: Theme.fontText; pixelSize: 12 }
                    color: Theme.textSecondary
                }

                Item {
                    id: strip
                    visible: sec.modelData.files.length > 0
                    anchors.fill: parent
                    anchors.margins: 12

                    Flickable {
                        id: flick
                        anchors.fill: parent
                        contentWidth: cells.width
                        contentHeight: height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: cells.width > width
                        flickableDirection: Flickable.HorizontalFlick

                        Behavior on contentX {
                            enabled: !flick.moving && !flick.flicking
                            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                        }

                        Row {
                            id: cells
                            spacing: 10
                            height: parent.height

                            Repeater {
                                model: sec.modelData.files

                                delegate: Item {
                                    id: cell
                                    required property var modelData
                                    width: 148
                                    height: 96

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 7
                                        color: Theme.dark ? "#1c1c20" : "#f2f3f6"
                                        clip: true

                                        AnimatedImage {
                                            anchors.fill: parent
                                            source: page.isGif(cell.modelData.path) ? "file://" + cell.modelData.path : ""
                                            fillMode: Image.PreserveAspectCrop
                                            sourceSize: Qt.size(296, 192)
                                            asynchronous: true
                                            visible: status === Image.Ready
                                        }
                                        Image {
                                            anchors.fill: parent
                                            source: !page.isGif(cell.modelData.path) && !page.isVideo(cell.modelData.path)
                                                    ? "file://" + cell.modelData.path : ""
                                            fillMode: Image.PreserveAspectCrop
                                            sourceSize: Qt.size(296, 192)
                                            asynchronous: true
                                            visible: status === Image.Ready
                                        }

                                        Rectangle {
                                            visible: page.isVideo(cell.modelData.path)
                                            anchors.centerIn: parent
                                            width: 26
                                            height: 26
                                            radius: 13
                                            color: Qt.rgba(0, 0, 0, 0.55)
                                            Text {
                                                anchors.centerIn: parent
                                                text: "\u25B6"
                                                color: "white"
                                                font.pixelSize: 11
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 7
                                            color: "transparent"
                                            border.width: 2
                                            border.color: page.current === cell.modelData.path
                                                          ? Theme.accent : "transparent"
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: page.apply(cell.modelData.path)
                                    }
                                }
                            }
                        }
                    }

                    WheelHandler {
                        target: flick
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: (event) => {
                            var dx = event.angleDelta.x
                            if (dx !== 0) {
                                flick.contentX = Math.max(0, Math.min(Math.max(0, flick.contentWidth - flick.width), flick.contentX - dx * 1.5))
                                event.accepted = true
                                return
                            }
                            var dy = event.angleDelta.y
                            if (dy !== 0 && flick.contentWidth > flick.width) {
                                var targetX = flick.contentX - dy * 1.5
                                if (targetX >= 0 && targetX <= (flick.contentWidth - flick.width)) {
                                    flick.contentX = targetX
                                    event.accepted = true
                                } else {
                                    if (targetX < 0) flick.contentX = 0
                                    else if (targetX > flick.contentWidth - flick.width) flick.contentX = flick.contentWidth - flick.width
                                    event.accepted = false
                                }
                            }
                        }
                    }

                    // Left-edge scroll button
                    Rectangle {
                        id: leftBtn
                        visible: flick.contentWidth > flick.width && flick.contentX > 8
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 56
                        radius: 14
                        color: Theme.dark ? Qt.rgba(0.1, 0.1, 0.12, 0.85) : Qt.rgba(1, 1, 1, 0.9)
                        border.width: 1
                        border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.15)
                        z: 10

                        Text {
                            anchors.centerIn: parent
                            text: "\u2039"
                            font { pixelSize: 24; bold: true }
                            color: Theme.dark ? "white" : "#222"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: flick.contentX = Math.max(0, flick.contentX - flick.width * 0.75)
                        }
                    }

                    // Right-edge scroll button
                    Rectangle {
                        id: rightBtn
                        visible: flick.contentWidth > flick.width && flick.contentX < (flick.contentWidth - flick.width - 8)
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 56
                        radius: 14
                        color: Theme.dark ? Qt.rgba(0.1, 0.1, 0.12, 0.85) : Qt.rgba(1, 1, 1, 0.9)
                        border.width: 1
                        border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.15)
                        z: 10

                        Text {
                            anchors.centerIn: parent
                            text: "\u203A"
                            font { pixelSize: 24; bold: true }
                            color: Theme.dark ? "white" : "#222"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: flick.contentX = Math.min(flick.contentWidth - flick.width, flick.contentX + flick.width * 0.75)
                        }
                    }
                }
            }
        }
    }

    Item { width: 1; height: 16 }
}
