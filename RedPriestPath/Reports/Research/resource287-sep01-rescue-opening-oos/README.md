# 资源287：救援联机开局缺失与17项DynamicModifier OOS事故报告

日期：2026-09-01  
候选：`0.1.0-rc.255／资源287`  
范围：只分析和修改`RedPriestPath`；Quick Deals及其他模组文件均未修改。

## 结论

资源286救援联机开局缺少永久联盟、中央76格视野和四座封印城，确实是本模组资源285引入并由资源286继承的启动接线回归。

救援Action Criteria已经启用，但主Gameplay在网络脚本载入期读取`GameConfiguration.GetValue("GAMEMODE_LOTM_RESCUE")`时可能得到`nil`，于是误判为普通模式，没有include／注册Phase1、Phase2A和Phase3；与此同时，三个独立救援网络上下文及旧CityBootstrap又按资源285的单一权威设计保持被动。最终没有任何上下文写入`LOTM_RESCUE_MODE`，后续Phase8也一直处于`active=false`，所以三个开局功能整链均未执行。

同局第一次同步检查出现的17项`DynamicModifier`差异是另一个本模组问题：六个工坊守卫在本地`ImprovementAddedToMap`回调中即时创建，其12个单位能力修改器与玩家／首城城区等5个修改器在两端以相反先后进入DynamicModifier档案。两端最终对象集合相同，但档案序号1792～1808错位，仍会被引擎判定为OOS。

## 证据覆盖

原始记录保留在：

- `C:\Users\20594\AppData\Local\Firaxis Games\Sid Meier's Civilization VI\Logs\Lua.log`：44,936字节、530行、最后写入2026-09-01 18:35:16；检查固定范围145～250、420～465，并按目标标记检索。
- `C:\Users\20594\AppData\Local\Firaxis Games\Sid Meier's Civilization VI\Logs\net_message_debug.log`：313,157字节、644行、最后写入2026-09-01 18:35:18；检查固定范围315～340及17项差异档案记录。

未展开历史封存、二进制、Base64或无关外部模组记录。

### 开局启动链

- `Lua.log:157`：主入口实际载入`MPTurnSync version=5 network=true source=ENTRYPOINT`。
- `Lua.log:160-230`：主Gameplay注册Lifecycle、Progression及后续系统，但没有`RescuePhase1`、`RescuePhase2A`或`RescuePhase3`的注册记录。
- `Lua.log:176,182,189,192-204`：Difficulty及Phase6～10均报告`active=false`或等价等待状态；Phase8 v6明确`active=false permanentAlliance=true`，说明默认联盟配置存在，但救援权威Property未建立。
- `Lua.log:231-234`：Phase1、Phase2A、Phase3三个独立网络上下文全部进入`passive ... master Gameplay owns ...`。
- `Lua.log:331`：旧CityBootstrap同样进入`passive network context`，没有提交同步补建命令。

上述证据排除“联盟配置被删除”“中央视野数值被改掉”或“其他模组阻止生成”；实际故障是所有预定执行者同时退出。

### 17项DynamicModifier差异

- `net_message_debug.log:322-326`：回合1结束开始第一次同步检查，并收到`numDeltaArchives=17`。
- `net_message_debug.log:329`起：差异类型为`DynamicModifier`；首项已显示同一档案槽在两端分别指向不同工坊守卫能力。
- 六个`UNIT_LOTM_PP_PATH_HOLDER`位于PlotIndex `5806、8202、6385、5684、2774、3453`；每个有两项相关能力，共12项。
- `SubValue=-274492200`映射`ABILITY_SEE_HIDDEN`，`SubValue=-256970712`映射`ABILITY_LOTM_PP_WORKSHOP_SEQUENCE_STRENGTH`。
- 其余5项属于Player 0、首城District及玩家英雄修改器；对象集合一致但创建顺序与12项工坊能力完全相反。
- `Lua.log:433-450`按回调到达顺序即时分类并创建上述六个守卫，与同步档案出现时间和对象一一对应。

## 资源287候选修复

### 救援开局

1. `LOTM_MP_TurnSync`升至v6，新增`IsRescueModeConfigured()`：优先检查只由救援Criteria执行的数据库资源`RESOURCE_LOTM_RESCUE_ALLY_BANNER`，不再依赖网络载入期可能缺失的自定义配置值。
2. 主Gameplay在网络救援局显式include Phase1、Phase2A、Phase3，并强制校验`Phase1 startup < Phase2A startup`及`Phase2 runtime < Phase3 runtime`；注册不完整时直接FATAL，不再静默开出残缺局。
3. CityBootstrap只在Phase2缺失／过期时提交同步`EXECUTE_SCRIPT`；Gameplay命令处理器调用有序startup。该同步边界只允许Phase1建立中央76格持续视野／领土锁、Phase2建立四城。
4. Phase8 v7增加窄入口`EstablishOpeningCoalition()`：仅在网络主上下文、救援数据库哨兵及Phase1／2 READY同时成立时建立引擎永久联盟；不调用全量`ReconcileAll`，不附加AI修改器、不引导单位、不推进Phase8状态。
5. Phase3、完整Phase8及其余startup/runtime继续要求`currentTurn > LOTM_RESCUE_PHASE2A_READY_GAME_TURN`，必须跨过完整世界回合，避免再次把大量动态修改器挤入同一开局边界。
6. 途径选择、生命周期、Advanced和偷盗者的救援判断统一使用同一哨兵；普通模式仍由反向Criteria和运行时检查双重隔离。

### 工坊OOS

1. 网络`ImprovementAddedToMap`回调只写Lua本地`{QueuedTurn, PlotIndex}`队列，不调用分类、单位创建、Ability或任何Plot／Game Property写入；单机继续走原即时路径。
2. 队列必须跨过完整世界回合，随后由最低存活主要文明的同步锚点按PlotIndex处理：`Classify → RegisterWorkshopPlot → SaveWorkshopRegistry → EnsureSequence`，且位于工坊单位／清营队列之前。
3. 工坊registry由v2升至v3，作为资源287的一次性旧档迁移；仅`version~=3`时按PlotIndex全图扫描。已分类营地不重抽，迁移后常驻处理仍为增量队列。

## 模式与存档边界

| 场景 | 候选行为 | 结论边界 |
|---|---|---|
| 全新救援联机局 | 同步补建76格、四城、永久联盟；下一完整世界回合才运行后续系统 | 最终验收首选，仍需双客户端实测 |
| 资源286已开坏的回合1／2救援档 | Phase2非READY时尝试补建；registry v3恢复现存营地 | 既往AI／外交／工坊／占地不回滚，可能无合法76格，不承诺无损 |
| 已正常READY的救援旧档 | UI不重复提交；Phase1／2／8按Property幂等恢复 | 设计兼容，仍需双客户端保存／重连实测 |
| 普通模式旧档 | 救援数据库哨兵不存在，不include Phase1／2／3，偷盗者保持可用 | 设计兼容，仍需双客户端重连实测 |
| 单机 | 保留原即时事件、随机和工坊分类路径 | 本轮未调整单机玩法数值 |

registry v3完成迁移后，若未来又发生“新营地生成后、下一稳定锚点前立即保存”，Lua本地队列本身不会进入存档，恢复仍依赖引擎在读档时重放改良事件；不能为了覆盖这一窗口而在本地回调写Gameplay权威状态，故列为资源287双端实测边界。

## 已完成验证与未完成门禁

已通过：全量`validate.py` 3261项、联机权威／确定性、偷盗者、UI、资源249保护、救援Phase1～10专项、现有Gameplay数据库神器／救援城数据只读检查，以及修改Lua的独立语法解析。

这些是静态、合成、数据库和语法证据，不等于游戏内或多人通过。资源287仍必须由完全相同的双客户端执行：

1. 全新救援局载入完成即看到中央76格、四座封印城和所有主要文明永久联盟。
2. 日志出现TurnSync v6的`rescueMode=true`、有序Phase1／2／3注册验证、Phase1／2 READY和opening coalition结果。
3. 跨至少两个完整世界回合，第一次及后续同步检查均无新的`DynamicModifier`或`LOTM_*`差异。
4. 保存、退出、重连后不重复生成城市、守卫、联盟或Modifier。
5. 另测正常READY救援旧档、普通旧档，以及资源286坏档的尽力恢复；坏档失败不能替代全新局验收。
