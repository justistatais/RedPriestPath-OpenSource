# 资源296最新单机金币、失控者与其他问题审计

## 输入与范围

- 日志根：`C:\Users\20594\AppData\Local\Firaxis Games\Sid Meier's Civilization VI\Logs`，最新会话至2026-09-06 22:05，`Lua.log` 1,943行／267,954字节。
- 审计`Lua.log`、`Player_Stats.csv`、`Barbarians.csv`、`Barbarians_Units.csv`、`Barbarian_ClansMode_ClanStats.csv`、`Barbarian_ClansMode_Events.csv`、`Database.log`、`Modding.log`和`UserInterface.log`。
- 只修改RedPriestPath单机路径；封存的`LOTM_MP_TurnSync.lua`、联机分支、Quick Deals及其他模组不动。

## 1. 序列9的50%金币

- `Lua.log:885`记录玩家0选定目标玩家4。`Lua.log:888,1011,1122,1232,1342,1460,1607,1717,1832`连续九次记录转移`7,7,7,7,8,9,9,11,11`，合计76金币。
- `Player_Stats.csv`中目标England的正向回合金样本为14、17、19、22，与日志的7、8、9、11分别等于`floor(yield*0.5)`。日志时点与CSV回合快照可差一个玩家回合，不影响这四组量级对应。
- 结论：50%计算与转移入口已在本局运行，没有“未执行”故障。原日志只写请求额，不能单独证明双方余额都真实变化。
- 修复：资源296单机路径在扣款、入账后立即回读双方余额，两个delta都精确等于50%请求额才提交；任一端部分失败按实际delta回滚。成功日志将同时写`yield/rate/amount/targetBefore/targetAfter/playerBefore/playerAfter`，并在玩家首都显示与本MOD现有掠夺收益一致的金色`+X [ICON_Gold]`世界浮字。

## 2. 失控者／疯狂者生成

- `Lua.log:50`表明Monsters模块正常加载，普通模式概率30%。但到第27回合没有任何`[LOTM_WORLD][Monsters] spawned`记录。
- 首个蛮族回合探针记录21个蛮族单位全部为`Workshops.Lookup.NO_CANDIDATE`；这批读档／建图单位没有进入任何工坊生成抽取。
- 第27回合的`Barbarian_ClansMode_Events.csv`先记录tribe 17创建，`Barbarians_Units.csv`同回合记录其长矛兵与帆船；随后`Lua.log:1830-1831`才记录plot 1274被分类为工坊并建立中央序列者。
- 根因：单机新部落创建会先发布初始单位`UnitAddedToMap`，后发布营地`ImprovementAddedToMap`。单位事件到达时该营地尚未分类，所以不是30%抽取失败，而是完全跳过了抽取入口。
- 修复：每座普通单机工坊以`LOTM_PP_WORKSHOP_BIRTH_RECONCILE_VERSION=1`为一次性版本门，按UnitID排序增量检查其半径3内“无工坊来源”的现存蛮族单位，重走原`ProcessUnitAdded`入口。因此当前资源295存档内已分类工坊也会在升级后修复一次，以后新工坊在分类当时修复。不做全图或每回合扫描，排除序列者、额外兵和既有失控者。每次尝试记录`spawned/result`。

## 3. 其他RedPriestPath问题

- `Lua.log:248-249`唯一RedPriestPath Lua错误是`UI/LOTM_TP_ControlPanel.lua:101` 的`end expected`。原因是资源295为隐藏旧右侧面板在函数中提前`return`，但仍保留后续语句，违反Lua的`return`必须是该语句块最后一条语句的语法。
- 修复：兼容上下文的`Initialize`只执行`ContextPtr:SetHide(true)`，无不可达语句；偷盗者继续使用与其他三途径一致的左上角LaunchBar和统一HUD。
- `Database.log:174-175`的Gameplay外键校验通过。`Modding.log`中Rulers of the Sahara和Catherine de Medici的XML警告、`Database.log`的CurrentClickouts／HallOfFame重复本地化均明确属于其他内容，本轮不修改。没有新的dump或packaged dump。

## 验证边界

- 完整发布器的29项门禁通过：主检3263项、失控者38项、偷盗者、联机权威／确定性、UI、Gameplay bundle以及Phase1至10专项失败0。
- 上述只证明静态、合成、构建与文件闭环；资源296仍需游戏内验收新格式金币delta日志，以及新工坊后的`birth units reconciled`、`monster attempt`和最终`spawned`。
