# 普通模式 OOS：红祭司自身代码复核

## 结论

本轮按用户要求只审计红祭司。当前最明确的本MOD风险不是外部模组的 `ANNEXED_STATES`，而是红祭司把大量 Gameplay 状态推进绑定到 `Events.PlayerTurnActivated`。这是本地“玩家回合激活”事件，不是双方共同的 Gameplay 回合锚点；多人客户端的触发顺序和触发对象可能不同。相关处理器会写同步 Player/Game/Unit Property，并调用同步随机数，足以解释“单独外部模组正常、加入红祭司后第一回合即 OOS”。

## 代码证据

红祭司当前脚本共有多处 `Events.PlayerTurnActivated.Add`，包括：

- `LOTM_RP_Lifecycle.lua:1427`：路径状态、持有者与序列推进。
- `LOTM_RP_Progression.lua:324`：晋升／消化状态。
- `LOTM_BE_BlackEmperor.lua:965`：黑皇帝产出与状态。
- `LOTM_RP_Advanced.lua:474`：高级路径效果。
- `LOTM_WORLD_Churches.lua:527`、`LOTM_WORLD_Events.lua:219`、`LOTM_WORLD_Monsters.lua:692`：世界事件、随机事件、魔物。
- `LOTM_PP_Perfect.lua:660`、`LOTM_PP_Artifacts.lua:643`、`LOTM_PP_Workshops.lua:493`：完美途径、封印物、工坊。

其中 `LOTM_WORLD_State.Random()` 直接调用 `Game.GetRandNum`；世界事件、教会奖励、魔物目标／游荡等均从这些回合处理器进入。若两端事件激活顺序不同，随机流会先分叉，再把不同结果写入同步 Property。

## 与日志的对应

本局 10:11:05 首次差异是 `Player.m_kProperties`，而非 QD 键；双方随后出现不同 `TypedVariantMap` 键。该形态与红祭司回合激活处理器在不同本地时序写入状态相符。日志中后续出现红祭司自身 `duplicate path holders`，证明本MOD生命周期在该局确实发生了状态异常；它晚于首个 OOS，不能单独作为首因，但说明生命周期处理仍需修复。

## 下载模组对照

- 海克斯扩展 `3765281534/GamePlay/Haikesi_Addon_GamePlay.lua:1556-1559`：Gameplay优先注册 `GameEvents.PlayerTurnStarted`，只有接口不存在才回退本地事件。
- More Historical Leaders `3754917538/Lua/FDR_Gameplay.lua:137`：金币、城市生产和Property结算直接注册 `GameEvents.PlayerTurnStarted`。
- 和而不同 `2465378070/Gameplay/RegionalYields.lua:253`、`ResourceClassification.lua:124`：区域产出和资源状态刷新使用 `GameEvents.PlayerTurnStarted`；其 UI 文件才使用 `Events.PlayerTurnActivated`。

共同边界是：修改 Gameplay 状态走同步 GameEvents；本地回合激活用于 UI。红祭司此前没有保持该边界。

## 已实施修复（rc.249／资源281）

1. 新增 `LOTM_MP_TurnSync.lua`。单机原样把同一 handler 注册到 `Events.PlayerTurnActivated`；网络多人把同一 handler 包装后注册到 `GameEvents.PlayerTurnStarted`。
2. 生命周期、进度、红祭司高级效果、完美、黑皇帝、偷盗者、封印物、工坊、教会、世界事件、魔物、AI教派和救援模块均改走统一入口；网络多人不再有绕过适配层的 Gameplay `PlayerTurnActivated.Add`。
3. 适配层在多人缺少同步接口时直接报错，不静默回退到本地事件；这避免以“功能继续运行”为名重新引入OOS。
4. Quick Deals兼容层仍只修改本地Lua缓存函数，不写同步Property；同时修正旧的“Properties are purged”误导日志，明确旧属性保留。

当前静态与构建检查不等于双客户端通过；仍需用相同资源281包复测第一回合及读档重连。
