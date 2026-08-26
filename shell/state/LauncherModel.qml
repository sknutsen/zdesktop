pragma Singleton
import QtQml
import Quickshell
import qs.core
import "launcherFilter.js" as LauncherFilter

Singleton {
    id: root

    property bool visible: false
    property string query: ""
    property string category: "all"
    property string status: "Loading applications..."
    property int selectedIndex: 0
    property var targetScreen: null
    property var apps: []
    property var categories: []
    property var filteredApps: []

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.parseApps();
        }
    }

    function categoryLabel(category) {
        const labels = {
            "AudioVideo": "Media",
            "Development": "Dev",
            "Education": "Learn",
            "Game": "Games",
            "Graphics": "Graphics",
            "Network": "Network",
            "Office": "Office",
            "Settings": "Settings",
            "System": "System",
            "Utility": "Tools"
        };

        return labels[category] || category;
    }

    function primaryCategory(app) {
        return LauncherFilter.primaryCategory(app.categories);
    }

    function refreshFilteredApps() {
        if (!root.visible) {
            root.filteredApps = [];
            root.selectedIndex = 0;
            return;
        }

        const apps = LauncherFilter.filterApps(root.apps, root.query, root.category);

        if (root.selectedIndex >= apps.length) {
            root.selectedIndex = Math.max(0, apps.length - 1);
        }

        root.filteredApps = apps;
    }

    function parseApps() {
        const apps = [];
        const categoryCounts = {};
        const allEntries = [...DesktopEntries.applications.values];

        for (const entry of allEntries) {
            if (!entry.command || entry.command.length === 0 || !entry.name) {
                continue;
            }

            const category = root.primaryCategory(entry);
            categoryCounts[category] = (categoryCounts[category] || 0) + 1;
            apps.push(entry);
        }

        const categories = [
            {
                "id": "all",
                "label": "All",
                "count": apps.length
            }
        ];
        const categoryIds = Object.keys(categoryCounts).sort(function (a, b) {
            return root.categoryLabel(a).localeCompare(root.categoryLabel(b));
        });

        for (const id of categoryIds) {
            categories.push({
                "id": id,
                "label": root.categoryLabel(id),
                "count": categoryCounts[id]
            });
        }

        root.apps = apps;
        root.categories = categories;
        root.status = apps.length === 1 ? "1 application" : apps.length + " applications";
        root.selectedIndex = 0;
        root.refreshFilteredApps();
    }

    function openWindow() {
        root.visible = true;
        root.query = "";
        root.category = "all";
        root.selectedIndex = 0;
        root.status = "Loading applications...";
        root.refreshFilteredApps();
        root.parseApps();
    }

    function open() {
        root.targetScreen = null;
        root.openWindow();
    }

    function openOnScreen(screen) {
        root.targetScreen = screen;
        root.openWindow();
    }

    function close() {
        root.visible = false;
        root.query = "";
        root.category = "all";
        root.filteredApps = [];
        root.selectedIndex = 0;
    }

    function toggle() {
        if (root.visible) {
            root.close();
        } else {
            root.open();
        }
    }

    function setQuery(value) {
        root.query = value;
        root.selectedIndex = 0;
        root.refreshFilteredApps();
    }

    function setCategory(value) {
        root.category = value;
        root.selectedIndex = 0;
        root.refreshFilteredApps();
    }

    function selectRelative(delta) {
        const apps = root.filteredApps;

        if (apps.length === 0) {
            root.selectedIndex = 0;
            return;
        }

        root.selectedIndex = (root.selectedIndex + delta + apps.length) % apps.length;
    }

    function selectAbsolute(index) {
        const apps = root.filteredApps;

        if (apps.length === 0) {
            root.selectedIndex = 0;
            return;
        }

        root.selectedIndex = Math.max(0, Math.min(index, apps.length - 1));
    }

    function launchApp(entry) {
        if (!entry || !entry.command || entry.command.length === 0) {
            return;
        }

        if (typeof entry.execute === "function") {
            entry.execute();
        } else {
            Quickshell.execDetached({
                "command": entry.command,
                "workingDirectory": entry.workingDirectory || ""
            });
        }

        root.close();
    }

    function launchSelectedApp() {
        const apps = root.filteredApps;

        if (apps.length === 0) {
            return;
        }

        root.launchApp(apps[root.selectedIndex]);
    }
}
