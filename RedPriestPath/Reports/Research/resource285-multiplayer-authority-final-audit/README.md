# 资源285联机权威最终静态审计

日期：2026-08-31  
候选：`0.1.0-rc.253 / resource 285`  
范围：只修多人Gameplay权威、确定性、载入／重连与本地提示边界；不修改单机handler、单机随机流、玩法数值、失控魔物参数或外部MOD。

## 已确认并修复的风险

1. **跨Gameplay上下文加载时序**：资源283的主AddGameplayScripts与ImportFiles同为204，实机先执行主入口并导致适配器nil。当前主入口内嵌并强制校验TurnSync v5；Gameplay依赖由202、共享适配器由203预载，业务入口为204。
2. **本地回合事件写权威状态**：网络多人不再把Gameplay writer直接挂到`Events.PlayerTurnActivated`。所有旧handler经统一适配器进入有序`GameEvents.PlayerTurnStarted`；单机仍注册原事件。
3. **启动／读档／重连竞态**：最低存活主要文明是共同启动锚点。每次Lua上下文重建先执行幂等startup，再用`LOTM_MP_TURNSYNC_LAST_CLAIMED_TURN:<PlayerID>`阻止同玩家同回合运行时重复结算。
4. **救援Phase1→2→3跨上下文竞争**：网络仅由主Gameplay上下文按Phase1、Phase2A、Phase3顺序注册和启动；三个独立AddGameplayScripts及旧CityBootstrap UI在网络保持被动。Phase2之后的其它startup和runtime至少跨过一个稳定游戏回合。
5. **共享RNG与枚举顺序**：多人随机为共同游戏／地图种子、当前回合和稳定事件键的纯函数，不推进GameCore RNG。关键文明、单位、城市、地块、Modifier与工坊条目均按稳定ID排序；单机继续使用`Game.GetRandNum`。
6. **工坊回调竞争**：普通蛮族生成只在回调中登记，按`QueuedTurn/Camp/Owner/Unit/Type`排序后由稳定锚点结算；清营按PlotIndex排序。两队列均隔一完整回合、逐项保存，保留失败后缀并恢复唯一在途token，避免重连整批重放。
7. **救援奖励与本地展示耦合**：工坊奖励、世界事件、教会奖励先提交权威ledger，随后才尽力执行`Locale`、`NotificationManager`或地图浮字；AI教派通知也已纳入该多人边界。纵火与己方掠夺浮字失败不会回滚Gameplay。
8. **Quick Deals可选依赖**：Criteria仍分为“QD存在”和“QD不存在”互斥路径；兼容脚本只在网络多人且Quick Deals真实加载时包装其本地报价缓存。无Quick Deals时不include脚本、不读写`QD_*`。本版不在载入期清除Property，也不迁移已经分叉的旧档缓存。

## UnitManager调用复核

| 系统 | 创建／删除／放置入口 | 多人确定性结论 |
|---|---|---|
| Lifecycle持有者 | startup、途径同步命令、同步回合 | 持有者按PlayerID处理，重复单位按UnitID排序；重建由路径和固定城市／相邻格决定。 |
| Phase3守卫 | 有序startup／回合 | 教会和阶位为固定序列，候选按Scope、距离、PlotIndex排序；旧档超额单位按UnitID清退。 |
| Phase10真神／外神 | 有序startup／回合及同步战斗事件 | 角色固定顺序，候选地块与阻挡单位稳定排序，角色Property和EngineKey作幂等账本。 |
| World Monsters | 有序蛮族回合及排序工坊队列 | 活体按MonsterSerial排序；出生地、目标、单位／城市候选均稳定排序；多人名称不写本地化文本。 |
| Workshops | 稳定锚点队列；单机保留即时UnitAdded | 多人全局计数、额外兵、魔物上限竞争按排序条目结算；救援普通蛮族即时删除只作用于该单对象，不消费随机或分配全局序号。 |
| 迁移／清理 | 版本门控startup | 蛮族Owner、玩家、单位按稳定ID排序；只执行一次迁移，不增加常驻全图扫描。 |

未发现UI直接修改金币、产出、Modifier、单位、城市或同步Property；UI主动操作仍只提交`EXECUTE_SCRIPT`并由Gameplay复核玩家和参数。

## 验证证据

- `python Tests/validate.py`：`PASS: 3261 static checks`
- `python Tests/validate_multiplayer_determinism.py`：通过
- `python Tests/validate_resource249_gameplay_baseline.py`：通过，四个受保护文件只含多人路由／启动分支；单机回落合同保留
- UI兼容22项、偷盗者、AI教派、随机事件、魔物、教会、救援Phase1～10及神器专项：通过
- `Scripts/*.lua + UI/*.lua`共69份，经去除Firaxis类型注解后由`luaparser`解析：0失败
- 2026-08-31 12:41的`DebugGameplay.sqlite`只读检查：21件神器、159个活动租约、AI教派、救援正式城市及外键检查通过。该数据库来自资源283实机；资源284／285没有新增Gameplay数据库结构。

## 尚未越过的边界

- 本报告是源码、数据库和模型门禁，不是双客户端游戏内通过。仍需按`Tests/MANUAL_TESTS.md`资源285清单验证新开普通／救援局、同回合保存重连、工坊并发、通知语言差异，以及有／无Quick Deals四种组合。
- 引擎Gameplay事件与`UnitManager`在两端成功／失败一致仍属于文明VI运行时合同；Lua无法对一端发生的引擎级异常提供跨客户端事务回滚，因此dispatcher会本地fail-closed并要求日志暴露首个故障。
- 本版明确不修复已经含不同`QD_BUYABLE_DEALS/QD_SELLABLE_DEALS`值的旧档；该类存档必须使用分叉前共同存档或重新开局验证。
