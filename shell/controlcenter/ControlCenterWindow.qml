import Quickshell
import qs.core
import qs.state

ClickAwayPopup {
    id: root

    required property var panelWindow

    readonly property int cardWidth: Theme.controlCenterWidth
    readonly property int maximumHeight: panelWindow && panelWindow.screen ? Math.max(240, panelWindow.screen.height - Theme.panelHeight - Theme.popupMargin) : 240

    visible: ControlCenterModel.visible
    targetWindow: panelWindow
    onDismissed: ControlCenterModel.close()

    ControlCenter {

        ControlButton {
            command: "loginctl lock-session"
            keybind: Qt.Key_L
            text: "Lock"
            // icon: "lock"
        }

        ControlButton {
            command: "loginctl terminate-user $USER"
            keybind: Qt.Key_E
            text: "Logout"
            // icon: "logout"
        }

        ControlButton {
            command: "systemctl suspend"
            keybind: Qt.Key_U
            text: "Suspend"
            // icon: "suspend"
        }

        ControlButton {
            command: "systemctl hibernate"
            keybind: Qt.Key_H
            text: "Hibernate"
            // icon: "hibernate"
        }

        ControlButton {
            command: "systemctl poweroff"
            keybind: Qt.Key_K
            text: "Shutdown"
            // icon: "shutdown"
        }

        ControlButton {
            command: "systemctl reboot"
            keybind: Qt.Key_R
            text: "Reboot"
            // icon: "reboot"
        }
    }
}
