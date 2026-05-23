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

        readonly property int previewWidth: 128
        readonly property int previewHeight: 76

        visible: false
        color: "transparent"
        implicitWidth: theme.floatingWindowWidth
        implicitHeight: theme.floatingWindowHeight
        exclusionMode: ExclusionMode.Normal
        focusable: true

        anchors {
            top: true
            left: true
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
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === Qt.Key_N && ctrl) {
                        listView.incrementCurrentIndex();
                        windowSwitcher.resetHintBuffer();
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K || event.key === Qt.Key_P && ctrl) {
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
                                orientation: ListView.Vertical
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

                                    width: parent.width
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

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: theme.listItemPadding
                                            spacing: theme.mediumGap

                                            Rectangle {
                                                Layout.alignment: Qt.AlignVCenter
                                                width: windowSwitcher.previewWidth
                                                height: windowSwitcher.previewHeight
                                                radius: theme.listItemRadius
                                                color: entry.ListView.isCurrentItem ? Qt.rgba(1, 1, 1, 0.10) : windowSwitcher.bgSecondary
                                                border.width: entry.matchedToplevel ? 1 : 0
                                                border.color: Qt.rgba(255, 255, 255, 0.08)
                                                clip: true

                                                Rectangle {
                                                    anchors.left: parent.left
                                                    anchors.top: parent.top
                                                    anchors.margins: 8
                                                    radius: 8
                                                    color: entry.ListView.isCurrentItem ? Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.95) : Qt.rgba(22 / 255, 22 / 255, 31 / 255, 0.90)
                                                    border.width: 1
                                                    border.color: entry.ListView.isCurrentItem ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(255, 255, 255, 0.08)
                                                    implicitWidth: hintText.implicitWidth + 14
                                                    implicitHeight: hintText.implicitHeight + 8

                                                    Text {
                                                        id: hintText
                                                        anchors.centerIn: parent
                                                        text: modelData.hint.toUpperCase()
                                                        color: entry.ListView.isCurrentItem ? windowSwitcher.bgPrimary : windowSwitcher.textPrimary
                                                        font.pixelSize: 11
                                                        font.weight: Font.DemiBold
                                                    }
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
                                                        font.pixelSize: 18
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

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                                spacing: theme.tightGap

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: theme.smallGap

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: windowSwitcher.windowLabel(modelData)
                                                        color: windowSwitcher.textPrimary
                                                        font.pixelSize: 14
                                                        font.weight: Font.Medium
                                                        elide: Text.ElideRight
                                                    }

                                                    Rectangle {
                                                        visible: modelData.active
                                                        radius: 8
                                                        color: Qt.rgba(87 / 255, 227 / 255, 137 / 255, 0.16)
                                                        border.width: 1
                                                        border.color: Qt.rgba(87 / 255, 227 / 255, 137 / 255, 0.35)
                                                        implicitWidth: activeText.implicitWidth + 16
                                                        implicitHeight: activeText.implicitHeight + 8

                                                        Text {
                                                            id: activeText
                                                            anchors.centerIn: parent
                                                            text: "active"
                                                            color: windowSwitcher.success
                                                            font.pixelSize: 11
                                                            font.weight: Font.Medium
                                                        }
                                                    }
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.className !== "" ? modelData.className : "Unknown app"
                                                    color: windowSwitcher.textMuted
                                                    opacity: 0.9
                                                    font.pixelSize: 12
                                                    font.weight: Font.Medium
                                                    elide: Text.ElideRight
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: theme.smallGap

                                                    Rectangle {
                                                        radius: 9
                                                        color: windowSwitcher.bgSecondary
                                                        implicitWidth: workspaceText.implicitWidth + 18
                                                        implicitHeight: workspaceText.implicitHeight + 8

                                                        Text {
                                                            id: workspaceText
                                                            anchors.centerIn: parent
                                                            text: windowSwitcher.workspaceLabel(modelData)
                                                            color: windowSwitcher.textMuted
                                                            font.pixelSize: 11
                                                            font.weight: Font.Medium
                                                        }
                                                    }

                                                    Rectangle {
                                                        radius: 9
                                                        color: windowSwitcher.bgSecondary
                                                        visible: modelData.monitorName !== ""
                                                        implicitWidth: monitorText.implicitWidth + 18
                                                        implicitHeight: monitorText.implicitHeight + 8

                                                        Text {
                                                            id: monitorText
                                                            anchors.centerIn: parent
                                                            text: modelData.monitorName
                                                            color: windowSwitcher.textMuted
                                                            font.pixelSize: 11
                                                            font.weight: Font.Medium
                                                        }
                                                    }
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

                    Rectangle {
                        Layout.fillWidth: true
                        height: theme.searchFieldHeight + 6
                        color: windowSwitcher.bgSecondary
                        radius: theme.searchFieldRadius
                        border.width: 0
                        border.color: windowSwitcher.accent

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: theme.searchFieldInset
                            anchors.leftMargin: theme.searchFieldLeftPadding
                            anchors.rightMargin: theme.searchFieldRightPadding
                            spacing: theme.mediumGap

                            Text {
                                text: "󰘳"
                                font.pixelSize: 20
                                color: windowSwitcher.textMuted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: "Arrow keys move. Enter jumps. Type hint letters to jump fast."
                                    color: windowSwitcher.textPrimary
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: windowSwitcher.hintBuffer === ""
                                        ? "Hints shown on cards. Esc closes."
                                        : "Typed hint: " + windowSwitcher.hintBuffer.toUpperCase()
                                    color: windowSwitcher.hintBuffer === "" ? windowSwitcher.textMuted : windowSwitcher.accentBright
                                    opacity: 0.9
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                            }
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
