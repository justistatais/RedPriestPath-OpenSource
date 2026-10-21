# rc353／资源385：旧档晋升恢复验收

- 完全退出游戏再加载已完成解密学者魔药的18或19回合旧档，观察持有者序列与消化。
- Lua.log 应在本次主模块加载后出现 `native potion receipt armed` 或状态日志；有原生完成凭据并满足前置时出现 `status=ADVANCED` 和 `native potion receipt consumed`，晋升序列7且消化重置。
- 若仍未晋升，按 `WAIT_NATIVE_COMPLETION`（原生要求/资源）、`PROGRESSION_REJECTED`（晋升门槛）或 `MISSING_*`（数据库/API）区分原因。日志仅状态变化时输出。
- 加载前的 UI 请求须等待新 main serial 和 LOADED；不能凭存档内 READY 提前投递。地图单位与营地请求同样保留排队。
- 新项目完成、取消项目、消化不足、非偷盗者、普通模式、重复事件、保存再加载分别检查；不得取消/重载后凭空升序列。
- 单机、独自多人房间、两客户端分别验收。自动测试只覆盖真实 Lua 控制流的替身环境及数据库/构建，不证明原生要求刷新时机或实机已通过。
