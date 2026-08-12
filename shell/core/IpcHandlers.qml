import Quickshell
import Quickshell.Io
import qs.state

Scope {
    IpcHandler {
        target: "launcher"

        function close(): void {
            LauncherModel.close();
        }

        function open(): void {
            LauncherModel.open();
        }

        function toggle(): void {
            LauncherModel.toggle();
        }
    }
}
