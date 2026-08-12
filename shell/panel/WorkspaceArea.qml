import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.core

RowLayout {
    id: root

    required property ShellScreen screen

    visible: Hyprland.workspaces.values.length > 0
    spacing: Theme.compactSpacing
    width: Math.min(implicitWidth, parent.width)
    height: parent.height

    anchors {
        left: parent.left
        verticalCenter: parent.verticalCenter
    }

    Repeater {
        model: Hyprland.workspaces.values

        delegate: Workspace {
            required property var modelData
            screen: root.screen
            workspace: modelData
        }
    }

    UiText {
        text: {
            const monitor = Hyprland.monitorFor(root.screen);
            const topLv = Hyprland.activeToplevel;

            if (topLv && monitor && topLv.monitor && topLv.monitor.id === monitor.id) {
                return topLv.title;
            } else {
                return "";
            }
        }
    }
}
