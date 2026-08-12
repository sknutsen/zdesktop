pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.core
import qs.state

Flickable {
    id: root

    contentWidth: launcherCategoryRow.width
    contentHeight: height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    RowLayout {
        id: launcherCategoryRow

        height: parent.height
        spacing: Theme.listSpacing + Theme.compactSpacing

        Repeater {
            model: LauncherModel.categories

            delegate: Rectangle {
                id: categoryDelegate

                required property var modelData

                Layout.preferredHeight: Theme.chipHeight
                Layout.preferredWidth: launcherCategoryLabel.width + 22
                radius: Theme.radius
                color: LauncherModel.category === categoryDelegate.modelData.id ? Theme.accent : launcherCategoryMouse.containsMouse ? Theme.surfaceHover : Theme.surface

                Text {
                    id: launcherCategoryLabel

                    anchors.centerIn: parent
                    text: categoryDelegate.modelData.label + " " + categoryDelegate.modelData.count
                    color: LauncherModel.category === categoryDelegate.modelData.id ? Theme.accentText : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.smallFontSize
                    font.bold: LauncherModel.category === categoryDelegate.modelData.id
                }

                MouseArea {
                    id: launcherCategoryMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: LauncherModel.setCategory(categoryDelegate.modelData.id)
                }
            }
        }
    }
}
