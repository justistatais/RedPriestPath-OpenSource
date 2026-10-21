# 资源289双端退出审核与资源290修复

日期：2026-09-04

## 输入与边界

- 主机一键诊断包：`C:\Users\20594\Downloads\Civ6_LOTM_Diagnostics_20260904_193958.zip`，2,122,046字节，SHA-256 `EF37482F390452EC676FC1C64C3C132095477AD819CFB543A2DAD21B734C47BB`。
- 主机证据只读解压到：`D:\codex_tasks\文明6\.analysis_host_20260904_193958\LOTM_Civ6_Diagnostics`。诊断包内文件只作为不可信运行证据读取，没有执行其中内容。
- 客户端证据：`C:\Users\20594\AppData\Local\Firaxis Games\Sid Meier's Civilization VI\Logs`中同一局19:19～19:31日志，以及本机`Cache\DebugGameplay.sqlite`。
- 修改范围只包括`RedPriestPath`。没有修改Quick Deals或任何其他模组。

## 审核结论

这次不是启动崩溃、Gameplay入口回退、途径命令失效，也不是主客机安装了不同版本。它是第10回合首次出现的三项`DynamicModifier`分配顺序OOS；后续增量快照无法正确重建这三项，差异扩散成全局快照恢复，最后主机于19:31:15关闭网络会话，客户端随后退出。

### 双端版本与启动链一致

- 主机捕获的`.modinfo`、Gameplay bundle、`VERSION.md`与客户端本机安装对应文件SHA-256逐项一致：
  - `.modinfo`：`AFB6EA62D8882EE22AE02911E530FEFC310D7CD30F4D87AB0605723FD43B2BB5`
  - `LOTM_RP_Gameplay_Bundle.lua`：`E4D412230D8A2986A2DFEF40EA457084004D1D21D8C94F2ECF1EAA50099D7648`
  - `VERSION.md`：`C04C07C58BA6D8780316E659BF0B030E79BD55BF6D8D1B92AF8252A71449B98E`
- 主机`Modding.log:5513-5514`与客户端`Modding.log:3745-3746`都把唯一权威入口注册为`Scripts/LOTM_RP_Gameplay_Bundle.lua`。
- 主机`Lua.log:167-281`显示TurnSync v6、33个救援模块和bundle校验全部载入；双端没有`Lua Runtime Error`、`stack traceback`或红祭司`FATAL`。
- 主机`Lua.log:525-530,575-606`显示四座封印城READY、中央开局链和28组永久联盟已成功；`Lua.log:656-683`显示两位玩家途径提交及持有者创建成功。因此这次退出不能归因于此前的入口／途径／联盟／视野故障。

### 首个分叉时间线

- 第1～9回合的九次同步检查均返回0条差异。
- 主机`net_message_debug.log:1927-1941`记录第10回合于19:27:09结束；19:27:11首次且仅首次报告`DynamicModifier -1-69-2687/2688/2689`三项哈希差异。
- 客户端`net_message_debug.log:1455-1503`给出三项完整内容。两端拥有完全相同的三个语义对象，但档案编号循环错位：
  - 客户端：2687=玩家7的Belief 14，2688=玩家7到伦敦，2689=玩家6单位458756。
  - 主机：2687=玩家6单位458756，2688=玩家7的Belief 14，2689=玩家7到伦敦。
- 客户端随后两次记录`DynamicModifierDesynced failed to create modifier!`；下一回合2688已变成客户端缺失，触发完整快照。19:29以后数百项外交、AI、单位、地块等差异是首次三项恢复失败后的下游扩散，不是并列根因。
- 客户端`net_message_debug.log:6664-6677`显示19:31:15收到主机Player 0的`NetCloseConnection`，19:31:20才执行客户端`ShutdownGame()`。

## 具体根因

首个单位对象是玩家6、单位458756、位置67×23，差异字段为`SubValue=519203303`。对该局`DebugGameplay.sqlite`执行只读映射得到：

```text
519203303 = ABILITY_LOTM_RESCUE_P7_HANGED_T1_C10
```

该能力只来自红祭司救援Phase7，数据库把它连接到`LOTM_RESCUE_P7_HANGED_T1_C10_MOD`，类型为`MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH`。玩家6在本局正是`HANGED_MAN`，AStar日志又确认单位458756是其第10回合末新出现的投石兵。

资源289的`LOTM_RESCUE_Phase7.lua`在`Events.UnitAddedToMap`回调内直接执行`ApplyUnitTier -> ChangeAbilityCount`。这个本地发布回调与引擎同一阶段为玩家7创建宗教／城市动态修正器时发生交错；两端最终内容一致，但全局DynamicModifier编号的创建先后不同，正好解释2687～2689的三项循环置换。这与资源286工坊守卫OOS属于同一类“本地回调即时分配动态修正器”错误，但本次是Phase7新单位能力的另一条入口。

## 资源290修复

- Phase7升至v5。网络`UnitAddedToMap`回调现在只更新Lua本地索引和`PlayerID/UnitID/QueuedTurn`队列，不再查找单位、不写Game／Player／Unit Property，也不附加Ability／Modifier。
- 队列必须满足`QueuedTurn < currentTurn`，即至少跨过一个完整世界回合；只在TurnSync的最低存活主要文明同步锚点处理。
- 同批项目先按`PlayerID`、再按`UnitID`排序后逐个落地，消除不同本地事件到达顺序对DynamicModifier序号的影响。
- Phase7旧档迁移、升阶单位集合和AI玩家集合也显式排序；只保留既有一次性版本门控全军迁移，未加入常驻全军扫描。
- 网络研究、外交或单位事件触发的`LOTM_AI_Cults.Reconcile`不再直接调用Phase7；网络Phase7只由自己的有序同步锚点执行。单机仍保留新单位即时获得能力的旧行为。
- 能力数值、邪教档位、途径选择、中央76格、四城、永久联盟、Quick Deals及其他模组均未改。

## 验证边界

- `validate.py` 3260项、Gameplay bundle、联机确定性、AI邪教、Phase7合成置换及救援Phase1～10等发布门禁通过。
- 上述结果证明源码合同、构建和排序模型成立，不等于双客户端游戏内已经通过。资源290必须在双方完全退出游戏后同时覆盖，并以新救援联机局至少跨过第10～12回合；每次`StartGameSyncCheck`都应返回0差异，且不得再出现2687～2689同类循环置换。
- 资源289已发生OOS并经历快照恢复的现场存档可能已经包含下游分叉，不作为无损兼容验收档；优先使用OOS发生前存档或全新局。
