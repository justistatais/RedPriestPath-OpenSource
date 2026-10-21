# 资源282联机权威链全审计

日期：2026-08-30  
范围：新开局；按用户决定不处理旧档已持久化的`QD_SELLABLE_DEALS/QD_BUYABLE_DEALS`差异。

## 已确认根因

1. 资源281虽然把`Scripts/LOTM_MP_TurnSync.lua`写入根`<Files>`，却遗漏于实际提供VFS的`LOTM_RP_UI_FILES` ImportFiles。`include("LOTM_MP_TurnSync")`因此返回空，随后40次模块初始化因全局为nil而终止。
2. 联机辅助器使用`GameConfiguration.IsNetworkMultiplayer()`；本机Firaxis UI、Quick Deals及主流下载模组采用公开可用的`GameConfiguration.IsAnyMultiplayer()`。旧判断在缺少该成员的Gameplay上下文会返回false，把联机误路由回本地`Events.PlayerTurnActivated`。
3. 多个模块在Gameplay脚本上下文加载时直接写Game／Player／Unit／Plot Property或附加Modifier。各客户端脚本上下文创建和GameCore初始快照时机不能作为同步结算锚点。

## 参考实现

- 海克斯扩展`3765281534/GamePlay/Haikesi_Addon_GamePlay.lua`：优先注册`GameEvents.PlayerTurnStarted`，仅在事件不存在时回退本地激活事件。
- 和而不同`2465378070` Gameplay脚本：涉及Property、Modifier、生产等回合结算大量使用`GameEvents.PlayerTurnStarted`。
- Quick Deals`2460661464`：多人判断使用`GameConfiguration.IsAnyMultiplayer()`；其界面刷新仍属于本地UI，不能成为本MOD Gameplay写状态的入口。

仅模仿同步事件与多人判定模式；未复制未明确授权的外部代码。

## 资源282修复

- 将`LOTM_MP_TurnSync.lua`同时纳入根`<Files>`和活动`LOTM_RP_UI_FILES` ImportFiles，并在主Gameplay入口中先于全部依赖模块加载。
- `LOTM_MP_TurnSync.VERSION=2`：单机继续使用原`Events.PlayerTurnActivated`；联机统一包装到`GameEvents.PlayerTurnStarted`；多人检测统一为`GameConfiguration.IsAnyMultiplayer()`；新增`RunStartup`，单机即时执行，联机延后到首个同步回合事件。
- 22个启动重建点接入`RunStartup`：Lifecycle、Progression、Perfect、BlackEmperor、Arson、Advanced、Thief、WorldState、AICults、Artifacts、Workshops、WorldMonsters、WorldChurches、WorldGoodyHuts、AICultHanged及救援Phase5/6/8/9/10A/10、救援神器。
- QD兼容层和Phase10联机专用分支也改用`IsAnyMultiplayer()`；没有Quick Deals时Action仍由`ModInUse` Criteria隔离，不加载兼容脚本。

## 确定性审计

- Gameplay脚本中没有`Game.GetLocalPlayer()`分支。
- 除辅助器的单机分支外，没有直接注册`Events.PlayerTurnActivated.Add`。
- UI脚本没有直接调用`SetProperty`、`AttachModifierByID`、`ChangeGoldBalance`或`GrantYield`修改同步状态；UI仅提交同步GameEvent命令。
- 全部同步随机调用共5处：神器工坊奖励、知识匣尤里卡、救援补营、村落奖励与世界事件。神器／科技候选显式排序；补营按PlotIndex扫描产生稳定候选；村落路径和等级使用固定数组；世界事件使用固定槽位排序。它们均由同步Gameplay事件进入。
- Lua table的`pairs()`只用于命令探针把参数键收集后排序再打印，不写入同步状态。
- Quick Deals兼容脚本不包含`SetProperty`，不会在加载期删除或改写旧缓存；本轮也不宣称旧档兼容。

## 门禁与边界

- 新增VFS门禁，防止“文件已纳包但include不可见”再次假通过。
- 新增多人API、同步启动、主入口加载顺序及22个启动点覆盖门禁。
- 3256项通用静态检查、联机确定性门、UI、偷盗者、资源保护、全部救援阶段与完整发布构建通过。
- 静态／构建通过不等于双客户端游戏内通过。新开局需确认双方均打印`[LOTM][MPTurnSync] initialized version=2 network=true`、各handler与startup日志，且首次GameSyncCheck不再出现LOTM Property差异。
