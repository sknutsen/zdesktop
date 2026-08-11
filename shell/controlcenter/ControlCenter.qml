import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

GridLayout {
  anchors.centerIn: parent
	property color backgroundColor: "#e60c0c0c"
	property color buttonColor: "#1e1e1e"
	property color buttonHoverColor: "#3700b3"

	default property list<ControlButton> buttons

  width: parent.width * 0.75
	height: parent.height * 0.75

	columns: 3
	columnSpacing: 0
	rowSpacing: 0

	Repeater {
		model: buttons
		delegate: Rectangle {
		  required property ControlButton modelData;

			Layout.fillWidth: true
			Layout.fillHeight: true

			color: ma.containsMouse ? buttonHoverColor : buttonColor
			border.color: "black"
			border.width: ma.containsMouse ? 0 : 1

			MouseArea {
				id: ma
				anchors.fill: parent
				hoverEnabled: true
				onClicked: modelData.exec()
			}

			Image {
				id: icon
				anchors.centerIn: parent
				// source: `icons/${modelData.icon}.png`
				width: parent.width * 0.25
				height: parent.width * 0.25
			}

			Text {
				anchors {
					top: icon.bottom
					topMargin: 20
					horizontalCenter: parent.horizontalCenter
				}

				text: modelData.text
				font.pointSize: 10
				color: "white"
			}
		}
	}
}
