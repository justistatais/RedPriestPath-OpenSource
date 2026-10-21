# Civ VI公开／本机MOD联机机制复核（资源284）

## 本次直接采用的模式

1. **Gameplay自包含关键依赖。** 海克斯主体与扩展都把权威Gameplay作为明确的`AddGameplayScripts`入口，不让核心状态处理依赖UI上下文。资源284进一步把回合同步适配器直接引导于红祭司主Gameplay入口，避免VFS include失败令整套Gameplay失效。
2. **ImportFiles早于消费者。** 海克斯扩展公开安装包使用ImportFiles LoadOrder 20005、Gameplay LoadOrder 20010。红祭司资源283两者同为204且日志中Gameplay先应用；资源284新增203的专用共享ImportFiles，Gameplay保持204。
3. **UI只提交、Gameplay校验。** 海克斯选择界面以`UI.RequestPlayerOperation(... EXECUTE_SCRIPT ...)`提交，Gameplay监听命令并写Property。红祭司继续保持此边界，途径选择UI不直接写同步状态。
4. **权威回合事件。** 海克斯扩展的产出／Property结算优先使用`GameEvents.PlayerTurnStarted`；`Events.PlayerTurnActivated`用于UI刷新。红祭司网络多人继续只用前者，单机才保留原事件。
5. **共同多人判定。** Sukritact公开知识库列出`GameConfiguration.IsAnyMultiplayer`可用于Gameplay和UI；资源284继续使用它，不退回较窄的网络判定。

## 公开资料

- Sukritact Civilization VI Modding Knowledge Base：
  - https://github.com/Sukritact/Civilization-VI-Modding-Knowledge-Base
  - `GameEvents.PlayerTurnStarted`：https://github.com/Sukritact/Civilization-VI-Modding-Knowledge-Base/blob/master/EventObjects/GameEvents/GameEvents.PlayerTurnStarted.md
  - `GameConfiguration.IsAnyMultiplayer`：https://github.com/Sukritact/Civilization-VI-Modding-Knowledge-Base/blob/master/Objects/GameConfiguration/GameConfiguration.IsAnyMultiplayer.md
  - `GameConfiguration.IsAnyMultiplayer`与Get/SetProperty接口也在其公开API索引中。
  - 本次读取提交：`144f27f5ea28c8a381f72343cad4c5ddbfb7c7b0`；仓库未提供可复用许可证，因此仅引用接口事实，不复制实现。
- CivFanatics公开讨论检索结果：
  - https://forums.civfanatics.com/threads/non-host-player-calling-initunit-and-kill-lua-functions-causing-re-sync-in-multiplayer-game.678526/
  - https://forums.civfanatics.com/threads/civ-vi-modded-multiplayer-desync.641154/
  - 论坛页面受浏览器校验保护，未把无法完整读取的回复当成已验证结论；只将其问题标题作为后续风险索引。
- Civ6 Mod Version Checker公开模板：
  - https://github.com/fekfekfek/Civ6ModVersionChecker
  - 明确提醒凡影响Gameplay／数据库的变化都应更新版本以暴露潜在不同步。本项目继续每版递增`.modinfo`资源版本并发布Manifest。
- 本机订阅参考（只研究行为与结构，不复制无明确许可代码）：海克斯大乱斗`3751996207`、海克斯扩展`3765281534`、Quick Deals`2460661464`、Annex City-States Remastered`3323036834`及Firaxis原生UI。

## 联机问题处理清单

| 风险 | 处理规则 | 当前门禁 |
|---|---|---|
| 核心include/VFS未执行 | 关键适配器在权威入口自举；ImportFiles显式更早；入口强制检查版本与函数 | 资源284新增 |
| UI按LocalPlayer写同步状态 | UI只读或提交`EXECUTE_SCRIPT`；Gameplay验证playerID和参数 | 已有扫描 |
| 本地回合事件写Gameplay | 网络使用`GameEvents.PlayerTurnStarted`；`PlayerTurnActivated`仅UI／单机适配 | 已有独立门禁 |
| 客户端随机调用次数不同 | 回调顺序敏感功能用共同种子+稳定ID哈希；必须使用Game RNG时只在共同事件、稳定排序后调用 | 工坊／偷盗者已处理；神器／事件仍需实机观察 |
| `pairs()`或数据库枚举顺序不同 | 候选集按PlayerID、UnitID、CityID、PlotIndex等稳定键排序后决定 | 静态与专项抽查 |
| 启动／读档时直接修改同步状态 | 多人延迟到首个同步Gameplay回合；迁移需版本Property幂等 | `RunStartup` |
| 本地缓存写Player Property | 缓存留在本地Lua内存；同步Property只保存共同玩法状态 | Quick Deals兼容层 |
| 直接创建／删除单位 | 只允许从同步Gameplay命令／共同事件执行，禁止UI或LocalPlayer分支直接调用 | UI写入扫描；救援仍需双端实测 |
| 双端文件或数据库索引不同 | 资源版本、Manifest、实际加载路径和双方Modding.log必须一致 | 构建／安装哈希；双端待验 |
| 重复回调、重连、存读档 | 回合／事件账本幂等，增量索引；迁移只运行一次 | 各专项检查 |

## 资源284实现

- `LOTM_RP_Gameplay.lua`在任何业务模块之前安装`LOTM_MP_TurnSync.VERSION=3`，校验`Add`与`RunStartup`，打印`source=ENTRYPOINT`；失败时只报一个明确FATAL错误。
- 保留`LOTM_MP_TurnSync.lua`供救援独立Gameplay上下文使用，并升级为v3、打印`source=INCLUDE`。
- 新增`LOTM_RP_GAMEPLAY_SHARED_FILES`，LoadOrder 203；主Gameplay和救援Gameplay均为204。
- 新门禁同时要求入口自举、不再include适配器、共享Import早于Gameplay，并继续阻止Gameplay读取LocalPlayer、UI直接写Property和网络回退到本地回合事件。

静态、构建与安装检查不能替代实机。资源284必须在全新启动的普通多人局看到`source=ENTRYPOINT`、Lifecycle handler与成功途径选择日志后，才能称该故障已在游戏内修复。
