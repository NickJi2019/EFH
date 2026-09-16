// 轻量客户端 i18n：加载 /i18n/<lang>.json，按 data-i18n* 属性回填文本。
// 用法：
//   <script src="/js/i18n.js" defer></script>
//   <span data-i18n="nav.home"></span>
//   <input data-i18n-placeholder="index.passwordPlaceholder">
//   <a data-i18n-title="...">
//   window.i18n.t("foo.bar", {n: 1})
(function () {
    "use strict";

    var SUPPORTED = ["zh-CN", "en"];
    var DEFAULT_LANG = "zh-CN";
    var FALLBACK_LANG = "zh-CN";
    var STORAGE_KEY = "lang";
    var SELECTOR = "[data-i18n],[data-i18n-html],[data-i18n-title],[data-i18n-placeholder],[data-i18n-aria-label]";

    var dict = {};
    var fallbackDict = {};
    var current = DEFAULT_LANG;
    var loaded = false;

    // 把一个语言标签（如 "zh-CN"、"en-US"、"zh"）映射到支持的语言
    function matchLang(tag) {
        if (!tag) {
            return null;
        }
        var t = String(tag).toLowerCase();
        for (var i = 0; i < SUPPORTED.length; i++) {
            if (SUPPORTED[i].toLowerCase() === t) {
                return SUPPORTED[i];
            }
        }
        var base = t.split("-")[0];
        for (var j = 0; j < SUPPORTED.length; j++) {
            if (SUPPORTED[j].toLowerCase().split("-")[0] === base) {
                return SUPPORTED[j];
            }
        }
        if (base === "zh") {
            return "zh-CN";
        }
        return null;
    }

    function detectLang() {
        // 优先按浏览器语言（按用户的偏好顺序）
        var tags = [];
        if (navigator.languages && navigator.languages.length) {
            tags = navigator.languages;
        } else if (navigator.language || navigator.userLanguage) {
            tags = [navigator.language || navigator.userLanguage];
        }
        for (var i = 0; i < tags.length; i++) {
            var matched = matchLang(tags[i]);
            if (matched) {
                return matched;
            }
        }
        // 浏览器语言都不支持时，回退到用户上次手动选择
        try {
            var saved = localStorage.getItem(STORAGE_KEY);
            if (saved && SUPPORTED.indexOf(saved) !== -1) {
                return saved;
            }
        } catch (e) {
            // localStorage 不可用
        }
        return DEFAULT_LANG;
    }

    function lookup(source, path) {
        var parts = path.split(".");
        var cur = source;
        for (var i = 0; i < parts.length; i++) {
            if (cur === null || typeof cur !== "object") {
                return undefined;
            }
            cur = cur[parts[i]];
        }
        return cur;
    }

    function pick(source, key) {
        // 支持扁平键（"nav.home"）与嵌套对象两种写法
        if (source && Object.prototype.hasOwnProperty.call(source, key)) {
            return source[key];
        }
        return lookup(source, key);
    }

    function t(key, params) {
        var val = pick(dict, key);
        if (typeof val !== "string") {
            val = pick(fallbackDict, key);
        }
        if (typeof val !== "string") {
            return key;
        }
        if (params) {
            val = val.replace(/\{(\w+)\}/g, function (match, name) {
                return params[name] !== undefined && params[name] !== null ? String(params[name]) : match;
            });
        }
        return val;
    }

    function collect(root) {
        var list = [];
        if (root.nodeType === 1 && root.matches && root.matches(SELECTOR)) {
            list.push(root);
        }
        if (root.querySelectorAll) {
            var found = root.querySelectorAll(SELECTOR);
            for (var i = 0; i < found.length; i++) {
                list.push(found[i]);
            }
        }
        return list;
    }

    function apply(root) {
        root = root || document;
        var nodes = collect(root);
        for (var i = 0; i < nodes.length; i++) {
            var el = nodes[i];
            if (el.hasAttribute("data-i18n")) {
                var text = t(el.getAttribute("data-i18n"));
                if (el.textContent !== text) {
                    el.textContent = text;
                }
            }
            if (el.hasAttribute("data-i18n-html")) {
                el.innerHTML = t(el.getAttribute("data-i18n-html"));
            }
            if (el.hasAttribute("data-i18n-title")) {
                el.setAttribute("title", t(el.getAttribute("data-i18n-title")));
            }
            if (el.hasAttribute("data-i18n-placeholder")) {
                el.setAttribute("placeholder", t(el.getAttribute("data-i18n-placeholder")));
            }
            if (el.hasAttribute("data-i18n-aria-label")) {
                el.setAttribute("aria-label", t(el.getAttribute("data-i18n-aria-label")));
            }
        }
        document.documentElement.lang = current;
    }

    function load(lang) {
        return fetch("/i18n/" + lang + ".json", {cache: "no-store"})
            .then(function (res) {
                return res.ok ? res.json() : {};
            })
            .catch(function () {
                return {};
            });
    }

    function setLang(lang) {
        if (SUPPORTED.indexOf(lang) === -1 || lang === current) {
            return;
        }
        current = lang;
        try {
            localStorage.setItem(STORAGE_KEY, lang);
        } catch (e) {
            // ignore
        }
        load(lang).then(function (data) {
            dict = data || {};
            apply(document);
            document.dispatchEvent(new CustomEvent("i18n:changed", {detail: {lang: lang}}));
        });
    }

    function observe() {
        if (!window.MutationObserver || !document.body) {
            return;
        }
        var observer = new MutationObserver(function (mutations) {
            observer.disconnect();
            for (var i = 0; i < mutations.length; i++) {
                var added = mutations[i].addedNodes;
                for (var j = 0; j < added.length; j++) {
                    if (added[j].nodeType === 1) {
                        apply(added[j]);
                    }
                }
            }
            observer.observe(document.body, {childList: true, subtree: true});
        });
        observer.observe(document.body, {childList: true, subtree: true});
    }

    document.addEventListener("click", function (e) {
        var target = e.target;
        var el = target && target.closest ? target.closest("[data-lang]") : null;
        if (el) {
            e.preventDefault();
            setLang(el.getAttribute("data-lang"));
        }
    });

    function init() {
        current = detectLang();
        document.documentElement.lang = current;
        Promise.all([load(current), load(FALLBACK_LANG)]).then(function (res) {
            dict = res[0] || {};
            fallbackDict = res[1] || {};
            loaded = true;
            apply(document);
            observe();
            document.dispatchEvent(new CustomEvent("i18n:ready", {detail: {lang: current}}));
        });
    }

    window.i18n = {
        t: t,
        apply: apply,
        setLang: setLang,
        getLang: function () { return current; },
        isReady: function () { return loaded; },
        supported: SUPPORTED.slice()
    };

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
})();
