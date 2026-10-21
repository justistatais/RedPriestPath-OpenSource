# rc.340 联机运行时入口审计

日期：2026-09-18。范围：手写 MP241 兼容层、后置载入桥、救赎城市启动 UI，以及对应 Lua 行为测试。未修改 rc.241 Phase1／Phase2／Phase3 城市创建主体；未修改生成器、版本、modinfo 或安装目录。

## 已证实的代码缺陷与修复

1. 原后置桥只监听 `LOTM_RESCUE_Command_BootstrapCity`，UI 在存档 Phase2 已 READY 时不再提交该命令。因此 READY 存档中的新 Lua 上下文没有恢复后增主 Bundle 的入口。现在 UI 每个上下文在关闭载入画面、当前玩家回合可操作且 Phase2 版本与 READY 已满足后提交一次独立 `LOTM_MP241_Command_LoadMain`。同步回合 fallback 完成城市初始化时，同样能经 UI publish 观察 READY 后继续。
2. 原 UI 的 `m_submitted` 只在各自客户端有效，多个人类客户端可以各自提交全局城市初始化。现在城市 bootstrap 由 ID 最小的存活人类大文明发起；后增主上下文恢复允许任何有效人类 UI 发起一次，以保证高 ID 玩家重连也有恢复入口。所有 Gameplay 客户端仍执行同一同步命令。Gameplay 重新校验请求玩家、救赎模式和 Phase2 就绪状态，不能只信 UI。已经载入的上下文只更新同步诊断确认，不重复 include、startup 或 catch-up。
3. 原 `include` 在已创建四城的 bootstrap 回调内执行，还没有 LOADING 重入锁；部分 include 失败后继续重试可能重复注册回调。现在使用独立同步操作，上下文状态固定为 WAITING→LOADING→LOADED/FAILED；部分失败关闭当前上下文重试。生成器发布的 `LOTM_MP241_MAIN_READY` 是完成证据，防止 Civ VI include 静默失败被误报为成功。
4. 存档的 LOADED Property 不等于新 Gameplay 上下文已恢复。上下文锁和保存的诊断 Property 分离；每次有效同步请求在所有端一致增加 `LOTM_MP241_MAIN_LOAD_SERIAL`，UI 仅在本次预期 serial 已达到后的 LOADED/FAILED 确认，防止旧存档状态被立即显示为本次成功。已载入端同样推进诊断 serial，避免重连端单独写 Property 导致确定性差异。
5. 后增模块原 `Add()` 使用 `Events.PlayerTurnActivated`，此类客户端通知不能作为联机权威写入入口。两个 Add 现统一直挂 `GameEvents.PlayerTurnStarted`，按稳定标签、玩家、世界回合持久去重，调用前登记避免重入与同回合读档重放部分已执行的写入。没有新建共享逐回合 dispatcher，没有加入全图常驻扫描。
6. 后增模块的 startup 原在模块载入时立即执行，普通网络路由下可发生于同步事件外。现在先登记，每个 startup 通过直接同步回合事件恢复一次；救赎独立 LoadMain 命令也在同步环境中统一完成待恢复 startup。配对标签的 turn handler 先执行自己的 startup。
7. 同步错误 Property 只写固定代码 `INCLUDE_OR_STARTUP_FAILED`。完整异常消息可能含各端本地路径，仅写本地日志。
8. 独立命令晚于当前回合的锚点事件，可能错过 Phase5Runtime 等本回合逻辑。因此 PreMain 提前监听同步 `PlayerTurnStarted`，只在此事件记录本回合已开始玩家的有序小型列表（`LOTM_MP241_STARTED_TURN/PLAYERS`）；LoadMain 完成 startup 后按玩家 ID、既有模块注册顺序调用原 wrapper 补跑，原持久标签去重防止重复。没有从本地 UI 状态推断任何待执行回合。
9. Civ VI 原生 API 对不存在的 Property 可能返回零个 Lua 值；直接 `tonumber(Game.GetProperty(key))` 会变成零参数 `tonumber()` 报错。补齐缺省值并在真实 Lua 中测试零返回值。

`RunStartup` 返回 false 的处理保留“一次载入只执行一次”的原兼容层语义。当前普通偷盗者 `RefreshThiefStartup` 的 false 是 `thiefFound=false`，表示完成恢复检查但尚无该途径，不是要求无限重试的信号；以后选择途径由正常 turn/lifecycle 处理。为等到玩家选中途径而逐回合重扫所有玩家会引入新热点。异常则标记 FAILED，当前上下文不重复部分执行的 startup。

## 参考边界

同轮订阅模组审计提供的 `3758337710` 资源种植 UI/Gameplay 使用 `RequestPlayerOperation(EXECUTE_SCRIPT,{OnStart=...})`，Gameplay 重新校验单位、位置、操作条件后落地。这里采用同样的“UI 提交同步命令、Gameplay 再验证”边界。部分订阅模组不声明多人支持，不能据其写法推断本项目多人已通过；本轮也没有照搬 UI 直接改 Property 或本地载入事件直接修改 Gameplay 的做法。

## 验证

执行：`python RedPriestPath/Tests/test_mp241_runtime.py`。18 个真实 Lua runtime 行为测试通过，涵盖同步入口、每玩家每回合去重、同回合上下文重建、重入、部分失败、重复注册、配置 bool/number/string/资源标记、静默 include 失败、请求玩家校验、新局两阶段命令、READY 存档恢复、旧 serial 不误确认、高 ID 玩家上下文恢复入口与已加载端不重复效果、同步事件 catch-up 与存档去重、原生 API 零返回值、单人／普通模式隔离和拒绝请求后的重试。

Lupa 依赖可使用标准安装；本工作区回退路径为 `.tmp/refactor-rc340-python`。测试环境使用 Civ VI API stubs，不包含原生城市引擎，也没有运行真实双客户端。因此不能据这些测试声称 EXCEPTION_ACCESS_VIOLATION、长期 OOS 或热加入已修复。新版本存档可从保存的同步 started 列表恢复 catch-up；rc.339 及更早 READY 存档若没有当前回合 started 记录，无法凭存档推断已经开始的所有玩家，必须等下一同步回合事件，可能不补当前已过去的回合效果。下一次完整重启的实机应检查：Phase2 READY 先出现，随后独立 post-241 main submitted／COMMIT／loaded；READY 存档仍补载一次；双客户端同回合 Gameplay 状态一致。真实断线重连的上下文恢复及 OOS 仍需专项实测。

原始三文件备份：`backups/refactor-rc340-mp/RedPriestPath/...`，保持原始相对路径与字节。
