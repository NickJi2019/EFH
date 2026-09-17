(function () {
    "use strict";

    var STORAGE_KEY = "efh.theme";
    var root = document.documentElement;

    function systemTheme() {
        return (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches)
            ? "dark"
            : "light";
    }

    function storedTheme() {
        try {
            var value = localStorage.getItem(STORAGE_KEY);
            return (value === "dark" || value === "light") ? value : null;
        } catch (e) {
            return null;
        }
    }

    function currentTheme() {
        return root.getAttribute("data-theme") === "dark" ? "dark" : "light";
    }

    /* 当前选择："light" / "dark" / "system" */
    function choice() {
        return storedTheme() || "system";
    }

    function updateMenu(selected) {
        var items = document.querySelectorAll("[data-theme-set]");
        for (var i = 0; i < items.length; i++) {
            var match = items[i].getAttribute("data-theme-set") === selected;
            items[i].classList.toggle("active", match);
            items[i].setAttribute("aria-pressed", match ? "true" : "false");
        }
    }

    function refreshMenu() {
        updateMenu(choice());
    }

    function apply(theme) {
        root.setAttribute("data-theme", theme);
    }

    function set(theme) {
        if (theme === "system") {
            try {
                localStorage.removeItem(STORAGE_KEY);
            } catch (e) {
                /* 忽略 */
            }
            apply(systemTheme());
            refreshMenu();
            return;
        }
        if (theme !== "dark" && theme !== "light") {
            return;
        }
        try {
            localStorage.setItem(STORAGE_KEY, theme);
        } catch (e) {
            /* 隐私模式等场景忽略 */
        }
        apply(theme);
        refreshMenu();
    }

    apply(storedTheme() || systemTheme());
    refreshMenu();

    /* 避免经 jQuery 注入的导航栏/页脚被浏览器缓存，改了内容却看不到 */
    if (window.jQuery && window.jQuery.ajaxSetup) {
        window.jQuery.ajaxSetup({cache: false});
    }

    if (window.matchMedia) {
        var mq = window.matchMedia("(prefers-color-scheme: dark)");
        var onSystemChange = function () {
            /* 系统默认时跟随系统 */
            if (!storedTheme()) {
                apply(systemTheme());
                refreshMenu();
            }
        };
        if (mq.addEventListener) {
            mq.addEventListener("change", onSystemChange);
        } else if (mq.addListener) {
            mq.addListener(onSystemChange);
        }
    }

    document.addEventListener("click", function (event) {
        var target = event.target;
        var el = target && target.closest ? target.closest("[data-theme-set]") : null;
        if (!el) {
            return;
        }
        event.preventDefault();
        set(el.getAttribute("data-theme-set"));
    });

    if (window.MutationObserver) {
        var observer = new MutationObserver(function () {
            refreshMenu();
        });
        observer.observe(root, {childList: true, subtree: true});
    }

    window.__efhTheme = {
        get: currentTheme,
        set: set,
        system: systemTheme
    };
})();
