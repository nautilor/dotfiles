import QtQuick
import QtQuick.Layouts
import "../shared" as Shared

Item {
    id: entry
    Shared.Theme { id: theme }
    required property var modelData
    required property int index

    width: parent.width
    height: modelData.imagePath !== "" ? 92 : 68

    function select() {
        copyToClipboard.selectedItem = modelData.raw;
        copyToClipboard.running = true;
    }

    function remove() {
        deleteEntry.targetId = modelData.raw;
        deleteEntry.running = true;
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: entry.ListView.view.currentIndex = entry.index
        onClicked: entry.select()
    }

    Rectangle {
        color: "transparent"
        radius: theme.listItemRadius
        width: parent.width
        height: parent.height

        RowLayout {
            anchors.fill: parent
            anchors.margins: theme.listItemPadding
            spacing: theme.mediumGap

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: entry.modelData.imagePath !== "" ? 68 : 44
                height: entry.modelData.imagePath !== "" ? 68 : 44
                radius: theme.listItemRadius
                color: entry.ListView.isCurrentItem ? Qt.rgba(1, 1, 1, 0.10) : clipboardWindow.bgSecondary
                clip: true

                Image {
                    anchors.fill: parent
                    visible: entry.modelData.imagePath !== ""
                    source: entry.modelData.imagePath !== "" ? "file://" + entry.modelData.imagePath : ""
                    fillMode: Image.PreserveAspectCrop
                    horizontalAlignment: Image.AlignHCenter
                    verticalAlignment: Image.AlignVCenter
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: entry.modelData.imagePath === ""
                    text: "TXT"
                    color: clipboardWindow.textMuted
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    color: clipboardWindow.textPrimary
                    text: entry.modelData.display !== "" ? entry.modelData.display : "Clipboard item"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    Layout.fillWidth: true
                    color: clipboardWindow.textMuted
                    opacity: 0.8
                    text: entry.modelData.imagePath !== "" ? `Image • ${entry.modelData.recorded}` : entry.modelData.recorded
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
