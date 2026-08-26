const assert = require("assert");
const fs = require("fs");
const path = require("path");

const filterPath = path.resolve(__dirname, "../shell/state/launcherFilter.js");
const {
    toStringList,
    textScore,
    listScore,
    primaryCategory,
    scoreApp,
    filterApps
} = eval(
    "(function () {\n" +
        fs.readFileSync(filterPath, "utf8") +
        "\nreturn { toStringList, textScore, listScore, primaryCategory, scoreApp, filterApps };\n})()"
);

function app(overrides) {
    return Object.assign({
        name: "Firefox",
        generic: "Web Browser",
        comment: "Browse the Web",
        categories: ["Network", "WebBrowser"],
        startupWmClass: "firefox",
        keywords: ["internet", "web"],
        id: "org.mozilla.firefox",
        primaryCategory: "Network"
    }, overrides);
}

const catalog = [
    app({}),
    app({
        name: "Vim",
        generic: "Text Editor",
        comment: "Edit text files",
        categories: ["Utility", "TextEditor"],
        startupWmClass: "vim",
        keywords: ["editor"],
        id: "vim",
        primaryCategory: "Utility"
    }),
    app({
        name: "Kitty",
        generic: "Terminal",
        comment: "A fast terminal emulator",
        categories: ["System", "TerminalEmulator"],
        startupWmClass: "kitty",
        keywords: [],
        id: "kitty",
        primaryCategory: "System"
    }),
    app({
        name: "Visual Studio Code",
        generic: "Text Editor",
        comment: "Code Editing. Redefined.",
        categories: ["Development", "IDE"],
        startupWmClass: "code",
        keywords: ["vscode"],
        id: "code",
        primaryCategory: "Development"
    })
];

function names(apps) {
    return apps.map(function (item) {
        return item.name;
    });
}

assert.deepStrictEqual(toStringList(["Development", "Utility"]), ["Development", "Utility"]);
assert.deepStrictEqual(toStringList("Development;Utility;"), ["Development", "Utility"]);
assert.deepStrictEqual(toStringList(null), []);
assert.strictEqual(primaryCategory(["Game", "Utility"]), "Game");
assert.strictEqual(primaryCategory([]), "Other");

assert.strictEqual(textScore("Firefox", ""), 1);
assert.ok(textScore("Firefox", "firefox") > textScore("Firefox", "fire"));
assert.ok(textScore("Visual Studio Code", "code") >= 3000);
assert.strictEqual(textScore(null, "fire"), 0);
assert.throws(function () {
    ["Network", "WebBrowser"].split(/[\s._-]+/);
}, TypeError);

assert.doesNotThrow(function () {
    textScore(["Network", "WebBrowser"], "web");
});
assert.ok(listScore(["Network", "WebBrowser"], "web") >= 3000);
assert.ok(listScore(["Development"], "dev") >= 3000);
assert.ok(textScore(["Development", "IDE"], "dev") >= 3000);

const emptyQuery = filterApps(catalog, "", "all");
assert.strictEqual(emptyQuery.length, catalog.length);

const firefoxMatches = filterApps(catalog, "fire", "all");
assert.deepStrictEqual(names(firefoxMatches), ["Firefox"]);

const editorMatches = filterApps(catalog, "editor", "all");
assert.ok(editorMatches.some(function (item) {
    return item.name === "Vim";
}));
assert.ok(editorMatches.some(function (item) {
    return item.name === "Visual Studio Code";
}));
assert.ok(editorMatches.every(function (item) {
    return item.name !== "Firefox" && item.name !== "Kitty";
}));

const categoryMatches = filterApps(catalog, "development", "all");
assert.deepStrictEqual(names(categoryMatches), ["Visual Studio Code"]);

const keywordMatches = filterApps(catalog, "vscode", "all");
assert.deepStrictEqual(names(keywordMatches), ["Visual Studio Code"]);

const idMatches = filterApps(catalog, "org.mozilla", "all");
assert.deepStrictEqual(names(idMatches), ["Firefox"]);

const systemApps = filterApps(catalog, "", "System");
assert.deepStrictEqual(names(systemApps), ["Kitty"]);

const filteredSystem = filterApps(catalog, "kit", "System");
assert.deepStrictEqual(names(filteredSystem), ["Kitty"]);

const noSystemFirefox = filterApps(catalog, "fire", "System");
assert.deepStrictEqual(names(noSystemFirefox), []);

const nullableApp = app({
    name: "Weird",
    generic: null,
    comment: undefined,
    categories: null,
    startupWmClass: "",
    keywords: undefined,
    id: "",
    primaryCategory: "Other"
});
assert.doesNotThrow(function () {
    scoreApp(nullableApp, "weird");
});
assert.deepStrictEqual(names(filterApps([nullableApp], "weird", "all")), ["Weird"]);
assert.deepStrictEqual(names(filterApps([nullableApp], "missing", "all")), []);

const ranked = filterApps(catalog, "code", "all");
assert.strictEqual(ranked[0].name, "Visual Studio Code");
assert.ok(ranked[0].launcherScore > (ranked[1] ? ranked[1].launcherScore : 0));

console.log("launcherFilter tests passed");
