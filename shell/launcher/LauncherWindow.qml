pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.state

FloatingWindow {
    id: root

    title: "zdk-launcher"
    visible: LauncherModel.visible
    screen: LauncherModel.targetScreen
    implicitWidth: 760
    implicitHeight: 560
    color: Theme.transparent

    function focusSearch() {
        launcherSearch.forceActiveFocus();
        launcherSearch.cursorPosition = launcherSearch.text.length;
    }

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(root.focusSearch);
        }
    }

    ShellSurface {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.popupSpacing

            Text {
                text: "Applications"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.titleFontSize
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                color: Theme.surface
                radius: Theme.radius

                TextInput {
                    id: launcherSearch

                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textStrong
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    text: LauncherModel.query
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.inputFontSize
                    clip: true

                    onTextChanged: LauncherModel.setQuery(text)

                    Keys.onPressed: function (event) {
                        const ctrl = event.modifiers & Qt.ControlModifier;

                        if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && ctrl)) {
                            LauncherModel.selectRelative(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && ctrl)) {
                            LauncherModel.selectRelative(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageDown) {
                            LauncherModel.selectRelative(8);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp) {
                            LauncherModel.selectRelative(-8);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Home) {
                            LauncherModel.selectAbsolute(0);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_End) {
                            LauncherModel.selectAbsolute(LauncherModel.filteredApps.length - 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            LauncherModel.launchSelectedApp();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape || (event.key === Qt.Key_C && ctrl)) {
                            LauncherModel.close();
                            event.accepted = true;
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    visible: launcherSearch.text.length === 0
                    text: "Search applications"
                    color: Theme.placeholder
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.inputFontSize
                }
            }

            Text {
                Layout.fillWidth: true
                text: LauncherModel.filteredApps.length + " shown / " + LauncherModel.status
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                elide: Text.ElideRight
            }

            LauncherCategoryRow {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
            }

            ListView {
                id: launcherResults

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.listSpacing
                model: LauncherModel.filteredApps

                onModelChanged: {
                    if (LauncherModel.filteredApps.length > 0) {
                        positionViewAtIndex(LauncherModel.selectedIndex, ListView.Contain);
                    }
                }

                Connections {
                    target: LauncherModel

                    function onSelectedIndexChanged() {
                        if (LauncherModel.filteredApps.length > 0) {
                            launcherResults.positionViewAtIndex(LauncherModel.selectedIndex, ListView.Contain);
                        }
                    }
                }

                delegate: LauncherResultDelegate {
                    width: launcherResults.width
                    selected: index === LauncherModel.selectedIndex
                }
            }
        }
    }
}
