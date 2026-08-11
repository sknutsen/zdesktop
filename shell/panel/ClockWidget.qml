import QtQuick
import qs.core
import qs.state

UiText {
  text: Time.time

  anchors {
    rightMargin: Theme.panelGap
  }

  font {
    bold: true
  }
}
