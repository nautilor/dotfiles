import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "../shared" as Shared

Scope {
    id: windowSwitcherScope

    PanelWindow {
        id: windowSwitcher
        Shared.Theme { id: theme }

        property var allWindows: []
        property bool pendingOpen: false
        property string hintBuffer: ""
        property int hintLength: 1
        readonly property string hintAlphabet: "arstneioqwfpgjkluyxcvbmzhd"

        readonly property color bgPrimary: theme.floatingBgPrimary
        readonly property color bgSecondary: theme.floatingBgSecondary
        readonly property color border: theme.floatingBorder
        readonly property color textPrimary: theme.floatingTextPrimary
        readonly property color textMuted: theme.floatingTextMuted
        readonly property color accent: theme.floatingAccent
        readonly property color accentBright: theme.floatingAccentBright
        readonly property color success: theme.floatingSuccess

        readonly property int previewWidth: 128 * 2
        readonly property int previewHeight: 76 * 2

        visible: false
        color: "transparent"
        implicitWidth: Screen.width - (theme.floatingWindowMargin * 2) - (theme.floatingContentPadding * 2) 
        implicitHeight: previewHeight + (theme.floatingWindowMargin * 2) + (theme.floatingContentPadding * 2) + (previewHeight / 4)
        exclusionMode: ExclusionMode.Normal
        focusable: true

        anchors {
        }

        margins {
        }

        function parseRows(text, keys) {
            return text.split("\n").filter(line => line.trim() !== "").map(line => {
                const parts = line.split("\t");
                const row = {};

                for (let index = 0; index < keys.length; index++)
                    row[keys[index]] = parts[index] || "";

                return row;
            });
        }

        function workspaceLabel(windowInfo) {
            if (windowInfo.workspaceName.startsWith("special:"))
                return "special " + windowInfo.workspaceName.slice("special:".length);
            if (windowInfo.workspaceName !== "")
                return "ws " + windowInfo.workspaceName;
            if (windowInfo.workspaceId !== "")
                return "ws " + windowInfo.workspaceId;
            return "unknown workspace";
        }

        function windowLabel(windowInfo) {
            const title = windowInfo.title.trim();
            const className = windowInfo.className.trim();

            if (title !== "")
                return title;
            if (className !== "")
                return className;
            return "Window";
        }

        function fallbackPreviewText(windowInfo) {
            const source = (windowInfo.className || windowInfo.title || "??").trim();

            if (source === "")
                return "??";

            const parts = source.split(/[\s._-]+/).filter(part => part !== "");
            if (parts.length >= 2)
                return (parts[0][0] + parts[1][0]).toUpperCase();

            return source.slice(0, 2).toUpperCase();
        }

        function toplevelForAddress(address) {
            return ToplevelManager.toplevels.values.find(toplevel => {
                if (!toplevel || !toplevel.HyprlandToplevel)
                    return false;

                return `0x${toplevel.HyprlandToplevel.address}` === address;
            }) || null;
        }

        function hintLengthForCount(count) {
            let length = 1;
            let capacity = windowSwitcher.hintAlphabet.length;

            while (count > capacity) {
                length++;
                capacity *= windowSwitcher.hintAlphabet.length;
            }

            return length;
        }

        function hintForIndex(index, length) {
            const base = windowSwitcher.hintAlphabet.length;
            let value = index;
            let hint = "";

            for (let position = 0; position < length; position++) {
                hint = windowSwitcher.hintAlphabet[value % base] + hint;
                value = Math.floor(value / base);
            }

            return hint;
        }

        function resetHintBuffer() {
            windowSwitcher.hintBuffer = "";
            hintResetTimer.restart();
        }

        function syncSelectionToHint() {
            if (windowSwitcher.hintBuffer === "")
                return;

            const matchIndex = windowSwitcher.allWindows.findIndex(windowInfo => windowInfo.hint.startsWith(windowSwitcher.hintBuffer));
            if (matchIndex >= 0)
                listView.currentIndex = matchIndex;
        }

        function handleHintInput(text) {
            if (text.length !== 1)
                return false;

            const key = text.toLowerCase();
            if (!windowSwitcher.hintAlphabet.includes(key))
                return false;

            const nextBuffer = (windowSwitcher.hintBuffer + key).slice(-windowSwitcher.hintLength);
            const exactIndex = windowSwitcher.allWindows.findIndex(windowInfo => windowInfo.hint === nextBuffer);

            windowSwitcher.hintBuffer = nextBuffer;
            hintResetTimer.restart();
            windowSwitcher.syncSelectionToHint();

            if (nextBuffer.length < windowSwitcher.hintLength)
                return true;

            if (exactIndex >= 0) {
                listView.currentIndex = exactIndex;
                windowSwitcher.focusSelected();
            } else {
                windowSwitcher.resetHintBuffer();
            }

            return true;
        }

        function closeMenu() {
            windowSwitcher.pendingOpen = false;
            windowSwitcher.visible = false;
            focusGrab.active = false;
            windowSwitcher.hintBuffer = "";
            windowSwitcher.allWindows = [];
        }

        function openMenu() {
            if (fetchWindows.running)
                return;

            windowSwitcher.pendingOpen = true;
            windowSwitcher.hintBuffer = "";
            fetchWindows.running = true;
        }

        function toggleMenu() {
            if (windowSwitcher.visible)
                windowSwitcher.closeMenu();
            else
                windowSwitcher.openMenu();
        }

        function focusSelected() {
            if (focusProcess.running || !listView.currentItem)
                return;

            listView.currentItem.activateWindow();
        }

        HyprlandFocusGrab {
            id: focusGrab
            windows: [windowSwitcher]
            onCleared: windowSwitcher.closeMenu()
        }

        Timer {
            id: hintResetTimer
            interval: 1100
            repeat: false
            onTriggered: windowSwitcher.hintBuffer = ""
        }

        Process {
            id: fetchWindows
            command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/window-switcher.sh" list']
            stdout: StdioCollector {
                onStreamFinished: {
                    const rows = windowSwitcher.parseRows(this.text, [
                        "address",
                        "workspaceId",
                        "workspaceName",
                        "className",
                        "title",
                        "monitorName",
                        "active"
                    ]);

                    windowSwitcher.hintLength = windowSwitcher.hintLengthForCount(rows.length);
                    windowSwitcher.allWindows = rows.map((windowInfo, index) => ({
                        address: windowInfo.address,
                        workspaceId: windowInfo.workspaceId,
                        workspaceName: windowInfo.workspaceName,
                        className: windowInfo.className,
                        title: windowInfo.title,
                        monitorName: windowInfo.monitorName,
                        active: windowInfo.active === "true",
                        hint: windowSwitcher.hintForIndex(index, windowSwitcher.hintLength)
                    }));
                    listView.currentIndex = windowSwitcher.allWindows.length > 0 ? 0 : -1;

                    if (windowSwitcher.pendingOpen) {
                        windowSwitcher.pendingOpen = false;
                        windowSwitcher.visible = true;
                        focusGrab.active = true;
                        hintResetTimer.restart();
                        mainWindow.forceActiveFocus();
                    }
                }
            }
        }

        Process {
            id: focusProcess
            property string targetAddress: ""
            command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/window-switcher.sh" focus "$1"', "_", targetAddress]

            onRunningChanged: {
                if (!running && targetAddress !== "") {
                    targetAddress = "";
                    windowSwitcher.closeMenu();
                }
            }
        }

        Item {
            anchors.fill: parent

            RectangularShadow {
                anchors.fill: mainWindow
                radius: mainWindow.radius
                blur: 5
                spread: 0.2
                color: Qt.darker(mainWindow.color, 1.6)
            }

            Rectangle {
                id: mainWindow
                anchors.fill: parent
                anchors.margins: theme.floatingWindowMargin
                color: windowSwitcher.bgPrimary
                radius: theme.floatingWindowRadius
                border.width: 0
                border.color: windowSwitcher.border
                clip: true
                focus: true

                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;

                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q && ctrl) {
                        windowSwitcher.closeMenu();
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_N && ctrl) {
                        listView.incrementCurrentIndex();
                        windowSwitcher.resetHintBuffer();
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H || event.key === Qt.Key_P && ctrl) {
                        listView.decrementCurrentIndex();
                        windowSwitcher.resetHintBuffer();
                    } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_L) {
                        windowSwitcher.focusSelected();
                    } else if (event.key === Qt.Key_C && ctrl) {
                        windowSwitcher.closeMenu();
                    } else if (windowSwitcher.handleHintInput(event.text)) {
                        event.accepted = true;
                        return;
                    }

                    event.accepted = true;
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: theme.floatingContentPadding
                    spacing: theme.largeGap

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ScrollView {
                            anchors.fill: parent
                            clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                            ListView {
                                id: listView
                                model: windowSwitcher.allWindows
                                currentIndex: windowSwitcher.allWindows.length > 0 ? 0 : -1
                                spacing: theme.listGap
                                orientation: ListView.Horizontal
                                keyNavigationWraps: false
                                preferredHighlightBegin: 0
                                preferredHighlightEnd: height
                                highlightRangeMode: ListView.ApplyRange
                                highlightMoveDuration: 150
                                highlightMoveVelocity: -1

                                highlight: Rectangle {
                                    radius: theme.listItemRadius
                                    color: windowSwitcher.accent
                                    opacity: 0.75

                                    Behavior on y {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                delegate: Item {
                                    id: entry
                                    required property var modelData
                                    required property int index

                                    width: windowSwitcher.previewWidth + (theme.listItemPadding * 2)
                                    height: windowSwitcher.previewHeight + (theme.listItemPadding * 2)
                                    readonly property var matchedToplevel: windowSwitcher.toplevelForAddress(modelData.address)

                                    function activateWindow() {
                                        if (focusProcess.running)
                                            return;

                                        focusProcess.targetAddress = modelData.address;
                                        focusProcess.running = true;
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onEntered: entry.ListView.view.currentIndex = entry.index
                                        onClicked: entry.activateWindow()
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        color: "transparent"
                                        radius: theme.listItemRadius

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: windowSwitcher.previewWidth
                                            height: windowSwitcher.previewHeight
                                            radius: theme.listItemRadius
                                            color: entry.ListView.isCurrentItem ? Qt.rgba(1, 1, 1, 0.10) : windowSwitcher.bgSecondary
                                            border.width: entry.matchedToplevel ? 1 : 0
                                            border.color: Qt.rgba(255, 255, 255, 0.08)
                                            clip: true

                                            Rectangle {
                                                z: 2
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                anchors.margins: 8
                                                radius: 8
																								color: entry.ListView.isCurrentItem ? windowSwitcher.accentBright : (modelData.active ? windowSwitcher.success : Qt.rgba(255, 255, 255, 0.12))
                                                border.width: 1
																								border.color: Qt.rgba(255, 255, 255, 0.12)
                                                implicitWidth: hintText.implicitWidth + 20
                                                implicitHeight: hintText.implicitHeight + 10

                                                Text {
                                                    id: hintText
                                                    anchors.centerIn: parent
                                                    text: modelData.hint.toUpperCase()
																										color: modelData.active ? windowSwitcher.bgPrimary : windowSwitcher.textPrimary
                                                    font.pixelSize: 14
                                                    font.weight: Font.DemiBold
                                                }
                                            }

                                            Rectangle {
                                                z: 2
                                                anchors.right: parent.right
                                                anchors.top: parent.top
                                                anchors.margins: 10
                                                width: 10
                                                height: 10
                                                radius: 5
                                                visible: modelData.active
                                                color: windowSwitcher.success
                                                border.width: 1
                                                border.color: Qt.rgba(1, 1, 1, 0.18)
                                            }

                                            ScreencopyView {
                                                anchors.fill: parent
                                                visible: entry.matchedToplevel
                                                captureSource: entry.matchedToplevel
                                                live: true
                                            }

                                            Column {
                                                anchors.centerIn: parent
                                                visible: !entry.matchedToplevel
                                                spacing: theme.microGap

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: windowSwitcher.fallbackPreviewText(modelData)
                                                    color: windowSwitcher.textPrimary
                                                    font.pixelSize: 22
                                                    font.weight: Font.DemiBold
                                                }

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: windowSwitcher.workspaceLabel(modelData)
                                                    color: windowSwitcher.textMuted
                                                    opacity: 0.85
                                                    font.pixelSize: 10
                                                    font.weight: Font.Medium
                                                }
                                            }
                                        }
                                    }
                                }

                                Keys.onReturnPressed: windowSwitcher.focusSelected()
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: windowSwitcher.allWindows.length === 0
                            text: "No windows open"
                            color: windowSwitcher.textMuted
                            opacity: 0.8
                            font.pixelSize: 16
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "windowSwitcher"

        function toggle() {
            windowSwitcher.toggleMenu();
        }

        function open() {
            windowSwitcher.openMenu();
        }

        function close() {
            windowSwitcher.closeMenu();
        }
    }
}
