import QtQuick
import QtQuick.Layouts
import qs.core

PanelPill {
    id: root

    signal activated

    Layout.preferredWidth: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    hovered: logoMouse.containsMouse

    Image {
        id: logoImage

        anchors.centerIn: parent
        width: 24
        height: 25.2
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
    }

    UiText {
        anchors.centerIn: parent
        visible: true || logoImage.status === Image.Error
        color: Theme.accent
        text: "󱄅"
        font.pixelSize: 20
        font.bold: true
    }

    MouseArea {
        id: logoMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
