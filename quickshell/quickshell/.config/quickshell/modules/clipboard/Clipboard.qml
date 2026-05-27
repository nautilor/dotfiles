import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "../shared" as Shared

Scope {
    id: clipboardScope

    PanelWindow {
        id: clipboardWindow
        Shared.Theme { id: theme }

        property string scriptPath: "$HOME/.config/quickshell/bin/clipse-visual.sh"
        property string query: ""

        readonly property color bgPrimary: theme.floatingBgPrimary
        readonly property color bgSecondary: theme.floatingBgSecondary
        readonly property color bgHighlight: theme.floatingBgHighlight
        readonly property color border: theme.floatingBorder
        readonly property color textPrimary: theme.floatingTextPrimary
        readonly property color textMuted: theme.floatingTextMuted
        readonly property color accent: theme.floatingAccent
        readonly property color accentBright: theme.floatingAccentBright
        readonly property color success: theme.floatingSuccess
        readonly property color danger: theme.floatingDanger

        implicitWidth: theme.floatingWindowWidth
        implicitHeight: theme.floatingWindowHeight
        visible: false
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        focusable: true

        anchors {
            top: true
            left: true
        }

        property var allItems: []
        property var filteredItems: []

        HyprlandFocusGrab {
            id: focusGrab
            windows: [clipboardWindow]
            onCleared: clipboardWindow.closeMenu()
        }

        function closeMenu() {
            clipboardWindow.visible = false;
            focusGrab.active = false;
            clipboardWindow.query = "";
            searchField.text = "";
        }

        function updateSearch() {
            const q = clipboardWindow.query.trim().toLowerCase();

            if (q === "") {
                clipboardWindow.filteredItems = clipboardWindow.allItems;
            } else {
                clipboardWindow.filteredItems = clipboardWindow.allItems.filter(item => {
                    const str = item.display.toLowerCase();
                    let i = 0;
                    let j = 0;

                    while (i < str.length && j < q.length) {
                        if (str[i] === q[j])
                            j++;
                        i++;
                    }

                    return j === q.length;
                });
            }

            listView.currentIndex = clipboardWindow.filteredItems.length > 0 ? 0 : -1;
        }

        function copySelected() {
            if (listView.currentItem)
                listView.currentItem.select();
        }

        Process {
            id: fetchHistory
            command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/clipse-visual.sh" list']
            stdout: StdioCollector {
                onStreamFinished: {
                    clipboardWindow.allItems = this.text.split("\n").filter(line => line.trim() !== "").map(line => {
                        const parts = line.split("\t");
                        const id = parts[0];
                        const display = parts[1] || "";
                        const imagePath = parts[2] || "";

                        return {
                            raw: id,
                            recorded: id,
                            display: display,
                            imagePath: imagePath
                        };
                    });

                    clipboardWindow.updateSearch();
                }
            }
        }

        Process {
            id: copyToClipboard
            property string selectedItem: ""
            command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/clipse-visual.sh" copy "$1"', "_", selectedItem]
            onRunningChanged: {
                if (!running && copyToClipboard.selectedItem !== "") {
                    clipboardWindow.closeMenu();
                    copyToClipboard.selectedItem = "";
                }
            }
        }

        Process {
            id: deleteEntry
            property string targetId: ""
            command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/clipse-visual.sh" delete "$1"', "_", targetId]
            onRunningChanged: {
                if (!running && targetId !== "") {
                    targetId = "";
                    fetchHistory.running = true;
                }
            }
        }

        Process {
            id: clearHistory
            command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/clipse-visual.sh" clear']
            onRunningChanged: {
                if (!running) {
                    clipboardWindow.allItems = [];
                    clipboardWindow.updateSearch();
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
                color: clipboardWindow.bgPrimary
                radius: theme.floatingWindowRadius
                border.width: 0
                border.color: clipboardWindow.border
                clip: true
                focus: true

                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;

                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q && ctrl) {
                        clipboardWindow.closeMenu();
                    } else if (event.key === Qt.Key_X && ctrl) {
                        if (listView.currentItem)
                            listView.currentItem.remove();
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === Qt.Key_N && ctrl) {
                        listView.incrementCurrentIndex();
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K || event.key === Qt.Key_P && ctrl) {
                        listView.decrementCurrentIndex();
                    } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_L) {
                        clipboardWindow.copySelected();
                    } else if (event.key === Qt.Key_Slash) {
                        searchField.forceActiveFocus();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_C && ctrl) {
                        clipboardWindow.closeMenu();
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
                                model: clipboardWindow.filteredItems
                                currentIndex: clipboardWindow.filteredItems.length > 0 ? 0 : -1
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
                                    color: clipboardWindow.accent
                                    opacity: 0.75

                                    Behavior on y {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                delegate: ClipboardDelegate {}
                                Keys.onReturnPressed: clipboardWindow.copySelected()
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: clipboardWindow.filteredItems.length === 0
                            text: clipboardWindow.allItems.length === 0 ? "Clipboard empty" : "No results found"
                            color: clipboardWindow.textMuted
                            opacity: 0.8
                            font.pixelSize: 16
                            font.weight: Font.Medium
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: theme.searchFieldHeight
                        color: clipboardWindow.bgSecondary
                        radius: theme.searchFieldRadius
                        border.width: 0
                        border.color: clipboardWindow.accent

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: theme.searchFieldInset
                            anchors.leftMargin: theme.searchFieldLeftPadding
                            anchors.rightMargin: theme.searchFieldCompactRightPadding
                            spacing: theme.mediumGap

                            Text {
                                text: ""
                                font.pixelSize: 22
                                color: clipboardWindow.textMuted
                            }

                            TextField {
                                id: searchField
                                Layout.fillWidth: true
                                placeholderText: "Search clipboard..."
                                font.pixelSize: 16
                                color: clipboardWindow.textPrimary
                                selectionColor: clipboardWindow.accent
                                selectedTextColor: clipboardWindow.bgPrimary
                                focus: true
                                leftPadding: theme.textFieldLeftPadding
                                rightPadding: 0
                                topPadding: 0
                                bottomPadding: 0
                                placeholderTextColor: clipboardWindow.textMuted
                                background: Rectangle {
                                    color: "transparent"
                                    border.width: 0
                                }

                                onTextChanged: {
                                    clipboardWindow.query = text;
                                    clipboardWindow.updateSearch();
                                }

                                Keys.onEscapePressed: clipboardWindow.closeMenu()
                                Keys.onPressed: event => {
                                    const ctrl = event.modifiers & Qt.ControlModifier;

                                    if (event.key === Qt.Key_Up || event.key === Qt.Key_P && ctrl) {
                                        event.accepted = true;
                                        if (listView.currentIndex > 0)
                                            listView.currentIndex--;
                                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_N && ctrl) {
                                        event.accepted = true;
                                        if (listView.currentIndex < listView.count - 1)
                                            listView.currentIndex++;
                                    } else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key)) {
                                        event.accepted = true;
                                        clipboardWindow.copySelected();
                                    } else if (event.key === Qt.Key_C && ctrl) {
                                        event.accepted = true;
                                        clipboardWindow.closeMenu();
                                    }
                                }
                            }

                            Rectangle {
                                id: clearButton
                                visible: clipboardWindow.allItems.length > 0
                                width: clearText.implicitWidth + 24
                                height: 36
                                radius: 10
                                color: clearHover.hovered ? clipboardWindow.danger : "transparent"
                                border.width: 1
                                border.color: clearHover.hovered ? clipboardWindow.danger : clipboardWindow.border
                                scale: clearTap.pressed ? 0.96 : 1.0

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutBack
                                    }
                                }

                                Text {
                                    id: clearText
                                    anchors.centerIn: parent
                                    text: "Clear"
                                    color: clearHover.hovered ? clipboardWindow.bgPrimary : clipboardWindow.textMuted
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                }

                                HoverHandler {
                                    id: clearHover
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    id: clearTap
                                    onTapped: clearHistory.running = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "clipMenu"

        function toggle() {
            if (clipboardWindow.visible) {
                clipboardWindow.closeMenu();
            } else {
                clipboardWindow.visible = true;
                fetchHistory.running = true;
                searchField.text = "";
                clipboardWindow.query = "";
                focusGrab.active = true;
                searchField.forceActiveFocus();
            }
        }
    }
}
