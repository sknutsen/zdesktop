import Quickshell
import QtQuick
import qs.controlcenter
import qs.core
import qs.panel

Scope {
    id: root

    property var selectedPanelWindow: null
    readonly property var defaultPanelWindow: panelVariants.instances.length > 0 ? panelVariants.instances[0] : null
    readonly property var activePanelWindow: selectedPanelWindow && selectedPanelWindow.screen ? selectedPanelWindow : defaultPanelWindow
    readonly property var activePanelScreen: activePanelWindow && activePanelWindow.screen ? activePanelWindow.screen : (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

    function selectPanelPopup(panel, popupId) {
        if (!panel || !popupId) {
            return;
        }

        if (popupId !== "controlcenter")
            ControlCenterModel.close();
        root.selectedPanelWindow = panel;
    }

    Variants {
        id: panelVariants

        model: Quickshell.screens

        ZdkPanel {
            required property var modelData

            screen: modelData

            onPopupRequested: (panel, popupId) => root.selectPanelPopup(panel, popupId)
        }
    }

    ControlCenterWindow {
        panelWindow: root.activePanelWindow
    }
}
