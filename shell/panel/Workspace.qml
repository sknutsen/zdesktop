import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.core

Rectangle {
  id: root

  required property HyprlandWorkspace workspace
  required property ShellScreen screen
  property var iconSources: []
  property int iconSourceIndex: 0

  Layout.preferredWidth: Theme.workspaceButtonSize
  Layout.preferredHeight: Theme.workspaceButtonSize
  radius: Theme.smallRadius

  color: {
    if (workspace.urgent) {
      return Theme.warning
    } else if (workspace.active) {
      return Theme.accent
    } else if (wsMouse.containsMouse) {
      return Theme.surfaceHover
    } else {
      return "transparent"
    }
  }
  visible: Hyprland.monitorFor(screen).id === workspace.monitor.id

    function openContextMenu() {
        if (root.workspace) {
        }
    }

    function handleClick(button) {
        if (button === Qt.LeftButton) {
          workspace.activate()
        } else if (button === Qt.MiddleButton) {
        }
    }
  
  IconImage {
    id: wsIcon

    anchors.centerIn: parent
    width: Theme.workspaceButtonSize
    height: Theme.workspaceButtonSize
    source: root.iconSources.length > root.iconSourceIndex ? root.iconSources[root.iconSourceIndex] : ""
    implicitSize: Theme.trayIconSize
    asynchronous: true
    mipmap: true
    visible: status === Image.Ready

    onStatusChanged: {
      if (status === Image.Error && root.iconSourceIndex < root.iconSources.length - 1) {
         root.iconSourceIndex += 1;
      }
    }
  }

  Text {
    anchors.centerIn: parent
    visible: !wsIcon.visible
    text: {
      if (workspace.name) {
        return workspace.name;
      }

      return workspace.id
    }
    color: Theme.text

    font {
      family: Theme.fontFamily
      pixelSize: Theme.panelFontSize
      bold: true
    }
  }

  MouseArea {
    id: wsMouse

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onPressed: mouse => {
      if (mouse.button === Qt.RightButton) {
        root.openContextMenu();
        mouse.accepted = true;
      }
    }

    onClicked: mouse => {
      if (mouse.button !== Qt.RightButton) {
        root.handleClick(mouse.button);
      }
    }
  }
}
