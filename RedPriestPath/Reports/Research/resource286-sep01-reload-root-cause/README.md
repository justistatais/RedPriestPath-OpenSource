# 资源286／2026-09-01 最新联机重新加载定因

## 结论

用户看到的“游戏重新加载”是文明VI在回合12末检测大规模OOS后执行网络快照恢复，不是普通UI刷新。首个OOS已在`09:52:30`的回合1末出现，直接可识别差异是两项Quick Deals缓存；它持续扩散，到`10:01:55`回合12末已成为58个差异档案并触发完整`NetSnapshot`。随后`10:02:03`进入`kRecieveMessage_LoadInProgress`，`10:02:40`从回合12末存档进入同步屏障，`10:02:46`重建后同步完成。

本次同时确认RedPriestPath资源285有两个必须修复的联机缺陷：

1. 首个同步差异的两个未知`TypedVariantMap`键，经文明VI哈希`~CRC32`反解为`QD_SELLABLE_DEALS`（59168906）和`QD_BUYABLE_DEALS`（4095584000）。资源285虽接管了Quick Deals后续缓存函数，却保留了接管前已写入且两端不同的同步Player Property。
2. `Lua.log`的494个Runtime Error全部来自`LOTM_RP_Gameplay.lua:207 ClaimNetworkTurn`：`tonumber(Game.GetProperty(key))`在动态claim Property尚不存在时实际调用无参`tonumber()`。该错误发生在startup之后、全部逐回合handler之前，使偷盗者及其它路径的有序联机runtime无法可靠执行；重新加载后同一错误再次出现。

因此资源286同时收敛“首个已知OOS差异”和“本模组唯一Runtime Error链”。Quick Deals及其它外部模组均不修改。

## 权威输入

- 上一任务“排查原因6-偷盗者”最后安装`0.1.0-rc.253／资源285`，当时文明VI尚未启动。
- 最新日志目录：`C:/Users/20594/AppData/Local/Firaxis Games/Sid Meier's Civilization VI/Logs`。
- `Lua.log`：1,577,113字节，最后写入2026-09-01 10:03:03，SHA-256 `C6DFBF54372C7C516A7C737B7E13624D1722924852F85C09EB7768A7A5C022F0`。
- `net_message_debug.log`：1,872,971字节，最后写入2026-09-01 10:03:04，SHA-256 `CAD3A06BDA31D9B8CC85B625D1B3C9C8361BE01E7BBAA1AD324AC63A1FB36497`。
- `Modding.log`：474,831字节，最后写入2026-09-01 10:03:06，SHA-256 `9042FEE461B1047CEC9AC779814017A37E5D567990130C89195BCC119183A89B`。

## 日志时间线

- `Lua.log:109`：资源285主入口成功自举`MPTurnSync version=5 network=true source=ENTRYPOINT`。
- `Lua.log:334`起：首次`ClaimNetworkTurn`缺值读取立刻报错；全日志唯一Runtime Error类型共494次，堆栈固定为第207／234行。
- `net_message_debug.log:240-252`：`09:52:30`第一回合末首个OOS为Player 0的`m_kProperties`，两端差异恰为上述两个Quick Deals哈希键。
- `net_message_debug.log:2042`起：回合12末同步检查扩散为58个差异档案。
- `net_message_debug.log:2959-2968`：请求并接收完整网络快照，随后进入载入状态。
- `net_message_debug.log:3025-3033`：从回合12末存档进入同步屏障并完成重建。
- `Lua.log:13895-13916`：LoadScreen切换后资源285Gameplay上下文重新初始化。
- `Lua.log:14141`以后：同一`ClaimNetworkTurn`错误在重建上下文中复发，证明快照恢复只缓解状态、没有消除代码根因。

## 代码修复

- `Scripts/LOTM_RP_Gameplay.lua`与`Scripts/LOTM_MP_TurnSync.lua`新增相同的`ReadNumericGameProperty`：先用局部变量接收Property，再在非nil时转换。
- 回合claim以及救援Phase2 READY回合的两处读取全部改用安全函数；首次缺值会正常写入claim，不再抛错或跳过runtime。
- `Scripts/LOTM_QD_MultiplayerCompat.lua`仍在脚本载入、`LoadGameViewStateDone`和`LoadScreenClose`阶段只安装本地包装器；仅在共同`GameEvents.PlayerTurnStarted`、最低存活主要文明锚点上按固定PlayerID／固定键清除遗留`QD_*`。
- 联机确定性门禁新增上述安全读取、同步清理和载入期只读约束。

## 边界

- 最新局实际选择的是Player 0 `PATH_PERFECT`、Player 1 `PATH_BLACK_EMPEROR`，没有直接选择`PATH_THIEF`；本次证明的是偷盗者共用联机分派器的根故障，不是偷盗者9～0每项玩法的实机验收。
- 当前修复后尚未启动文明VI。双客户端新局应确认：首次同步检查不再出现两个QD哈希键、`Lua.log`中该`tonumber`错误为0、每回合出现持久claim且不再次进入`LoadInProgress`。
- 静态、Lua解析、构建与安装哈希只能证明发布一致，不能替代上述双客户端实测。

## 修复候选验证记录

- `python Tests/validate.py`：`PASS: 3261 static checks`。
- `python Tests/validate_multiplayer_determinism.py`、`python Tests/validate_thief_path.py`、UI、资源249基线及全部救援专项：通过。
- 本轮三份修改脚本（`LOTM_RP_Gameplay.lua`、`LOTM_MP_TurnSync.lua`、`LOTM_QD_MultiplayerCompat.lua`）经独立 Lua 解析：3/3 通过。
- 资源286候选包初次构建：691文件，SHA-256 `FA10E4495BFF03912251DA8E9A5D0F73B547DD24BCC5A8100F0771395B05EC9C`；最终包会在工作记录收口后重建。
- 覆盖前资源285安装已备份：`backups/RedPriestPath-installed-resource285-before-resource286-20260901.zip`，690文件，SHA-256 `18E45C0D23FF2222A20C17EC85D4B14E9C8B7C47ED04DB2949A52FCF655CCA82`。
- 资源286候选包已覆盖本机 `Mods/RedPriestPath`；安装目录回读为资源286、691文件，缺失0、额外0、哈希差异0。该次覆盖后因纳入本记录会再做一次最终重建与覆盖。
