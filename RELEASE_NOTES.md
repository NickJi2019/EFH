# EFH Website Blocking Detection v1.1.4

## English

This release adds an automatic update check on startup: the app asks GitHub for
a newer client release and, when one exists, shows a dialog with the bilingual
release notes. From there you can go to the download page, skip that version, or
turn the prompt off entirely. A new "Software update" section in Settings lets
you control the startup check and the new-version prompt, review the current
version, check manually, and undo a skipped version. This release also raises
the minimum window size on Windows, macOS and Linux so the layout stays usable,
stacks the source and list segmented controls vertically on very narrow screens,
stops the live log from auto-scrolling as soon as you scroll and resumes only
when you return to the bottom, and links the Cloudflare token field to the
official guide for creating a token.

## 中文

本次更新新增启动时自动检查更新：应用启动后会向 GitHub 查询是否有更新的客户端版本，
如有则弹窗展示双语更新说明。你可以选择「前往更新」「跳过此版本」或「不再显示」。
设置页新增「软件更新」区，可开关启动时自动检查和发现新版本时的弹窗，查看当前版本、
手动检查更新，以及取消已跳过的版本。本次还提高了 Windows、macOS、Linux 的最小窗口尺寸，
避免布局被压坏；在极窄屏幕上让数据来源/列表来源的分段控件改为纵向排列；实时日志在你滚动时
立即停止自动滚动，并在你回到底部后才恢复；CF Token 输入框新增创建令牌官方文档的链接。
