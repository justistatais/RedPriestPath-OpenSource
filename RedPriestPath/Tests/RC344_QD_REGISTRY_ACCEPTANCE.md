# rc.344／资源376：独自创建多人房间启动复验

本版根据资源375的同次Lua、网络日志与dump，修复QD旧缓存迁移盲扫0—63号槽位的行为。第一个未返回调用是玩家20的GetProperty；该局真实玩家含0—19及62、63。rc.241没有该兼容脚本。当前只处理GetWasEverAliveIDs登记名单，含已灭亡玩家，名单不可用则暂缓迁移且不标完成。

先完全退出文明VI再启动，以一个真人创建多人房间新局。诊断版本须为`[LOTM_DIAG] r=376`；不要把安装检查或Lua测试作为实机成功。

依次核对：

1. `ctx=QDCompat point=PLAYER REGISTRY BEFORE`、`PLAYER REGISTRY AFTER`、`PLAYER REGISTRY IDS`给出引擎名单；未登记的槽位不应有`CACHE READ BEFORE`。每次读取／清理都有AFTER，最后出现`CACHE MIGRATION COMPLETE`。如果为`CACHE MIGRATION DEFERRED`，记录原因；这表示尚未完成迁移。
2. 途径选择实际可见、可提交，城市`bootstrap submitted`／`accepted`、Phase2 READY、Phase3及后置MainBundle按现有策略继续。首次激活玩家之前的转圈不能独立作为世界回合已推进的证据；资源375的网络日志只记录世界回合1。
3. 成功进入操作后，实际进行后续回合并保存／载入；迁移版本仍为1，已完成存档不得再次扫描。双客户端和重连另行验收。

若仍崩溃，先保存本次Logs与同时间dump再重开，沿新的最后一对BEFORE／AFTER判断。密集临时诊断会增大日志，暂不用于性能比较。日志位于`%LOCALAPPDATA%\Firaxis Games\Sid Meier's Civilization VI\Logs`，不能误读Documents下的旧路径。
