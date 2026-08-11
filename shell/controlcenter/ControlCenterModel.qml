import Quickshell
import Quickshell.Io
import qs.core

pragma Singleton

Singleton {
  id: root

  property bool visible: false

  function open() {
    root.visible = true;
  }

  function close() {
    root.visible = false;
  }
}
