# 诡秘之主单位与玩法 · RedPriestPath

Civilization VI: Gathering Storm 的非官方《诡秘之主》模组源码。
Lua Gameplay / UI、SQL / XML 数据与运行资源均位于 `RedPriestPath/`。
steam链接：https://steamcommunity.com/sharedfiles/filedetails/?id=3780342356&utm_source=chatgpt.com

| 版本 | 资源号 | Git 分支 / 标签 |
| --- | --- | --- |
| 当前开发快照 0.1.0-rc.403 | 435 | `main` / `v0.1.0-rc.403` |
| Steam 发布版 0.1.0-rc.361 | 393 | `steam` / `v0.1.0-rc.361` |

**本快照：0.1.0-rc.403 / 资源 435。**

Steam 工坊：[诡秘之主单位与玩法](https://steamcommunity.com/sharedfiles/filedetails/?id=3780342356)。
两个快照按各自原始源码逐文件复制，以 `SOURCE_MANIFEST.sha256` 校验；
不包含私人对话、运行日志、存档、备份、机器安装报告或历史工作日志。

## 使用

需要 Civilization VI 与 Gathering Storm（风云变幻）。下载所需分支或标签，
将其中的 `RedPriestPath` 文件夹放入游戏的 `Mods` 文件夹，在游戏模组菜单中启用。
使用本地版本时先禁用同一 Mod ID 的 Steam 工坊副本，避免重复加载。
详细功能、安装与限制见 [模组 README](RedPriestPath/README.md)、
[INSTALL](RedPriestPath/INSTALL.md)、[VERSION](RedPriestPath/VERSION.md) 和
[KNOWN_LIMITATIONS](RedPriestPath/KNOWN_LIMITATIONS.md)。

## 验证边界

本次开源只做版本、发布包清单、复制哈希与资源引用检查，不新增游戏内或多人通过结论。
rc.403 / 435 的正式风暴次数、旧档迁移、即时瞄准和双端行为仍有待实测边界。
rc.361 / 393 已有救赎联机开局建城失败、进而卡住选择途径的报告；未宣称修复。
Gameplay 状态由同步事件修改，UI 读取 Property 或通过 EXECUTE_SCRIPT 提交请求。

## 开发

`RedPriestPath/Tests/` 包含验证和构建脚本。部分数据库、游戏安装目录及美术工具检查需要
本机游戏/SDK 环境；离线检查不能代替真实单机或双客户端测试。
原构建脚本位于 `RedPriestPath/Tests/build_release.py`，其数据库要求以脚本说明为准。

## 授权

原创代码与文档采用 [MIT](LICENSE)；美术及第三方材料的授权范围见 [NOTICE](NOTICE.md)。
This is an unofficial fan mod. Original code is MIT licensed; third-party and art rights are retained.
