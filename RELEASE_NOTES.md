# EFH Website Blocking Detection v1.1.5

## English

This release fixes two Android issues. Rotating the device during a run no
longer freezes the UI: the shell now keeps the page and its state (including the
live result list) instead of rebuilding it whenever the layout crosses a width
breakpoint. Tapping the update or download button now opens GitHub: an app
cannot launch a browser process itself on Android, so the link is handed to the
system browser through a small platform channel.

## 中文

本次修复两个安卓问题。检测过程中旋转屏幕不再卡死：跨过布局宽度断点时，外壳会保留页面及其状态
（包括实时结果列表），不再把整棵页面树重建。点击更新/下载按钮现在能打开 GitHub：安卓上应用
无法自行启动浏览器进程，改为通过一个轻量的平台通道把链接交给系统浏览器处理。
