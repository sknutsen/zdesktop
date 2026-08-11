import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.core
import qs.controlcenter

pragma ComponentBehavior: Bound

PanelWindow {
  id: root

  signal popupRequested(panelWindow: var, popupId: string)

  implicitHeight: Theme.panelHeight
  color: Theme.barBackground
  exclusiveZone: Theme.panelHeight
  // aboveWindows: root.state.fullscreenMonitorIndexes.indexOf(root.state.screenIndex(root.screen)) === -1

  anchors {
    top: true
    left: true
    right: true
  }

  Rectangle {
    id: island

    anchors {
      fill: parent
      leftMargin: Theme.panelEdgeMargin
      rightMargin: Theme.panelEdgeMargin
      topMargin: Theme.panelMargin
      bottomMargin: Theme.panelMargin
    }
        
    color: Theme.barBackground

    border {
      color: Theme.border
      width: Theme.pillBorderWidth
    }

    opacity: 1.0
    radius: Theme.barRadius

    RowLayout {
      spacing: Theme.panelGap

      anchors {
        fill: parent
        leftMargin: Theme.panelGap
        rightMargin: Theme.panelGap
      }

      LogoButton {
        id: logoButton
        onActivated: {
          root.popupRequested(root, "controlcenter");
          ControlCenterModel.open();
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumWidth: 0            

        WorkspaceArea {
          screen: root.screen
        }
      }

      ClockWidget {}
    }
  }
}
