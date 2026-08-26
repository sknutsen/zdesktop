function toStringList(value) {
    if (value == null || value === "") {
        return [];
    }

    if (typeof value === "string") {
        const parts = value.split(/[;,]+/);
        const result = [];

        for (let i = 0; i < parts.length; i++) {
            const part = parts[i].trim();
            if (part.length > 0) {
                result.push(part);
            }
        }

        return result;
    }

    const length = value.length;
    if (typeof length !== "number") {
        return [String(value)];
    }

    const result = [];
    for (let i = 0; i < length; i++) {
        const item = value[i];
        if (item != null && String(item).length > 0) {
            result.push(String(item));
        }
    }

    return result;
}

function isList(value) {
    return value != null && typeof value !== "string" && typeof value.length === "number";
}

function textScore(text, query) {
    const needle = query == null ? "" : String(query).trim().toLowerCase();

    if (needle.length === 0) {
        return 1;
    }

    if (isList(text)) {
        return listScore(text, needle);
    }

    if (text == null || text === "") {
        return 0;
    }

    const haystack = String(text).toLowerCase();
    const words = haystack.split(/[\s._-]+/);

    if (haystack === needle) {
        return 10000;
    }
    if (haystack.indexOf(needle) === 0) {
        return 5000;
    }
    for (let i = 0; i < words.length; i++) {
        if (words[i].indexOf(needle) === 0) {
            return 3000;
        }
    }
    if (haystack.indexOf(needle) >= 0) {
        return 1000;
    }

    let offset = 0;
    for (let i = 0; i < needle.length; i++) {
        offset = haystack.indexOf(needle.charAt(i), offset);
        if (offset < 0) {
            return 0;
        }
        offset++;
    }

    return 250;
}

function listScore(values, query) {
    const items = toStringList(values);
    let best = 0;

    for (let i = 0; i < items.length; i++) {
        const itemScore = textScore(items[i], query);
        if (itemScore > best) {
            best = itemScore;
        }
    }

    return best;
}

function primaryCategory(categories) {
    const items = toStringList(categories);
    const priority = ["Development", "Game", "Graphics", "Network", "Office", "AudioVideo", "Settings", "System", "Utility", "Education"];

    for (let i = 0; i < priority.length; i++) {
        if (items.indexOf(priority[i]) >= 0) {
            return priority[i];
        }
    }

    return "Other";
}

function scoreApp(app, query) {
    const needle = query == null ? "" : String(query).trim().toLowerCase();
    const nameScore = textScore(app && app.name, needle);
    const genericScore = textScore(app && app.generic, needle) * 0.65;
    const commentScore = textScore(app && app.comment, needle) * 0.45;
    const categoryValue = listScore(app && app.categories, needle) * 0.35;
    const classScore = textScore(app && app.startupWmClass, needle) * 0.5;
    const keywordScore = listScore(app && app.keywords, needle) * 0.55;
    const idScore = textScore(app && app.id, needle) * 0.55;

    return Math.max(nameScore, genericScore, commentScore, categoryValue, classScore, keywordScore, idScore);
}

function filterApps(apps, query, category) {
    const source = apps || [];
    const needle = query == null ? "" : String(query).trim().toLowerCase();
    const filtered = [];

    for (let i = 0; i < source.length; i++) {
        const app = source[i];
        if (category && category !== "all" && app.primaryCategory !== category) {
            continue;
        }

        const appScore = scoreApp(app, needle);
        if (appScore <= 0) {
            continue;
        }

        app.launcherScore = appScore;
        filtered.push(app);
    }

    filtered.sort(function (a, b) {
        if (b.launcherScore !== a.launcherScore) {
            return b.launcherScore - a.launcherScore;
        }

        const nameA = appName(a);
        const nameB = appName(b);
        return nameA.localeCompare(nameB);
    });

    return filtered;
}

function appName(app) {
    return app && app.name ? String(app.name) : "";
}
