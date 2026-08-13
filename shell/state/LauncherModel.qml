pragma Singleton
import QtQml
import Quickshell
import qs.core

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
        const categories = app.categories;
        const priority = ["Development", "Game", "Graphics", "Network", "Office", "AudioVideo", "Settings", "System", "Utility", "Education"];

        for (const wanted of priority) {
            if (categories.indexOf(wanted) >= 0) {
                return wanted;
            }
        }

        return "Other";
    }

    function textScore(text, query) {
        if (query.length === 0) {
            return 1;
        }

        const words = text.split(/[\s._-]+/);

        if (text === query) {
            return 10000;
        }
        if (text.indexOf(query) === 0) {
            return 5000;
        }
        for (const word of words) {
            if (word.indexOf(query) === 0) {
                return 3000;
            }
        }
        if (text.indexOf(query) >= 0) {
            return 1000;
        }

        let offset = 0;
        for (let i = 0; i < query.length; i++) {
            offset = text.indexOf(query.charAt(i), offset);
            if (offset < 0) {
                return 0;
            }
            offset++;
        }

        return 250;
    }

    function categoryScore(categories, query) {
        var scr = 0;

        for (const category of categories) {
            scr = scr + textScore(category, query);
        }

        return scr;
    }

    function score(app, query) {
        const needle = query ? query.trim().toLowerCase() : "";
        const nameScore = root.textScore(app.name.toLowerCase(), needle);
        const genericScore = root.textScore(app.generic.toLowerCase(), needle) * 0.65;
        const commentScore = root.textScore(app.comment.toLowerCase(), needle) * 0.45;
        const categoryScore = root.textScore(app.categories, needle) * 0.35;
        const classScore = root.textScore(app.startupWmClass.toLowerCase(), needle) * 0.5;

        return Math.max(nameScore, genericScore, commentScore, categoryScore, classScore);
    }

    function refreshFilteredApps() {
        if (!root.visible) {
            root.filteredApps = [];
            root.selectedIndex = 0;
            return;
        }

        const needle = root.query.trim().toLowerCase();
        const apps = [];

        for (const app of root.apps) {
            if (root.category !== "all" && app.primaryCategory !== root.category) {
                continue;
            }

            const appScore = root.score(app, needle);
            if (appScore <= 0) {
                continue;
            }

            app.launcherScore = appScore;
            apps.push(app);
        }

        apps.sort(function (a, b) {
            if (b.launcherScore !== a.launcherScore) {
                return b.launcherScore - a.launcherScore;
            }

            return a.name.localeCompare(b.name);
        });

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
            if (!entry.command || entry.command.length === 0) {
                continue;
            }

            // TODO: clean. not really necessary
            const app = {
                "name": entry.name,
                "generic": entry.genericName,
                "comment": entry.comment,
                "exec": entry.command,
                "workingDirectory": entry.workingDirectory,
                "icon": entry.icon,
                "categories": entry.categories,
                "startupWmClass": entry.startupClass,
                "actions": entry.actions
            };

            app.primaryCategory = root.primaryCategory(app);
            categoryCounts[app.primaryCategory] = (categoryCounts[app.primaryCategory] || 0) + 1;
            apps.push(app);
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

    function launchApp(app) {
        if (!app || !app.exec || app.exec.length === 0) {
            return;
        }

        Quickshell.execDetached({
            "command": app.exec,
            "workingDirectory": app.workingDirectory || ""
        });
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
