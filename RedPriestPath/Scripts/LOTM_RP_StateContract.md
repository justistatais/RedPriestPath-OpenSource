# HUD 只读状态契约（阶段 05 发布候选）

正式 HUD 只能读取 `Game.GetLocalPlayer()` 对应玩家的同步 Player Property；
不得借助普通 `LuaEvents` 请求 Gameplay 写入，也不得读取或展示其他玩家的途径状态。
纵火按钮只通过 `UnitManager.RequestCommand(..., EXECUTE_SCRIPT, ...)` 提交同步命令；
谋划目标选择只通过 `UI.RequestPlayerOperation(..., EXECUTE_SCRIPT, ...)` 提交同步命令。
序章漫画首开确认只通过 `LOTM_RP_Command_MarkOpeningComicShown` 提交同步命令；
UI本地标记只用于封闭命令发布前的重复点击窗口，不是存档真值。
序列0过场只读取同步序号/回合/确认字段，并通过
`LOTM_RP_Command_AcknowledgeSequence0Ceremony`同步确认已播放。

可公开读取的字段与含义：

| Property | 类型 | 默认值 | 含义 |
|---|---:|---:|---|
| `LOTM_RP_STATE_VERSION` | number | `35` | 状态结构版本；新增正常模式偷盗者权威状态，保留封印物同步类型—实例映射 |
| `LOTM_RP_PROMOTION_TREE_MIGRATED` | number | `1` | 状态25一次性持有者重建／旧晋升快照清理完成标志 |
| `LOTM_RP_PATH` | string | `NONE` | 同步后的逐玩家途径选择 |
| `LOTM_RP_SEQUENCE` | number | `9` | 当前序列 |
| `LOTM_RP_DIGEST_A` | number | `0` | 当前序列 A 类计数 |
| `LOTM_RP_DIGEST_B` | number | `0` | 当前序列 B 类计数；两类合计上限 6 |
| `LOTM_RP_DIGEST_TURN` | number | `-1` | 最近增加消化点的绝对游戏回合 |
| `LOTM_RP_DIGEST_TURN_GAIN` | number | `0` | 该回合已增加点数；普通事件上限2，序列4寄生的显式+3事件按单次幂等爆发结算 |
| `LOTM_RP_UNIT_ID` | number | `-1` | 当前存活英雄 ID；不存在时为 `-1` |
| `LOTM_RP_RESPAWN_AT` | number | `-1` | 待复活的绝对游戏回合；无计划时为 `-1` |
| `LOTM_RP_ARSON_READY_AT` | number | `-1` | 纵火再次可用的绝对游戏回合；`-1` 表示从未使用 |
| `LOTM_RP_PLAN_TARGET_ID` | number | `-1` | 阴谋家当前选择的存活主要文明目标 |
| `LOTM_RP_PLAN_TARGET_READY_AT` | number | `-1` | 再次切换谋划目标的绝对游戏回合 |
| `LOTM_RP_PLAN_WAS_AT_WAR` | number | `-1` | 与当前谋划目标的上一轮同步战争状态 |
| `LOTM_RP_PLAN_GOLD_ACTIVE` | number | `0` | 当前是否处于对谋划目标的战争中；供金币提示只读 |
| `LOTM_RP_PLAN_GOLD_MODIFIER_ACTIVE` | number | `0` | 原版每回合金币Modifier当前是否维持净+100 |
| `LOTM_RP_SEQUENCE0_CEREMONY_SERIAL` | number | `0` | 任一途径序列1→0晋升产生的专属过场序号 |
| `LOTM_RP_SEQUENCE0_CEREMONY_READY_TURN` | number | `-1` | 过场允许显示的首个回合 |
| `LOTM_RP_SEQUENCE0_CEREMONY_ACK_SERIAL` | number | `0` | Gameplay已接受确认的过场序号 |
| `LOTM_RP_OPENING_COMIC_SHOWN` | number | `0` | Gameplay已接受本存档玩家的序章漫画首开确认；设为1后面板只正常开关 |
| `LOTM_TP_TARGET_PLAYER` | number | `-1` | 偷盗者共同目标；只允许已遇见的非队友主要文明 |
| `LOTM_TP_TARGET_CHANGED_TURN` | number | `-999` | 最近一次有效切换共同目标的绝对回合 |
| `LOTM_TP_LAST_PROCESSED_TURN` | number | `-1` | 偷盗者逐玩家回合结算去重标记，防止读档／重复事件重复发放 |
| `LOTM_TP_LAST_FAKE_GOLD_REDEEM_TURN` | number | `-1` | 最近一次显式兑换假金币的回合摘要 |
| `LOTM_TP_BORROWED_CIV` | string | 空 | 序列2当前借用的文明类型；Gameplay验证后写入 |
| `LOTM_TP_FINAL_BRANCH` | string | `NONE` | 序列0永久方向：`TECH_CIVIC`／`FAITH`／`CULTURE` |
| `LOTM_TP_*_BUFFER` | number | `0` | 无当前研究／生产项目时保存的同步待兑现产出 |
| `LOTM_TP_LAST_PRODUCTION_SETTLEMENT_TURN` | number | `-1` | 最近一次由同步 `EXECUTE_SCRIPT` 成功注入生产队列的回合；与生产缓冲共同防止重复结算 |
| `LOTM_TP_LAST_KNOWLEDGE_STEAL_SOURCE` / `_TURN` | number | `-1` | 最近一次科技／文化／信仰任一项成功结算的来源玩家与游戏回合；UI只读，用于当回合顶栏来源显示 |
| `LOTM_TP_LAST_KNOWLEDGE_STEAL_SCIENCE` / `_CULTURE` / `_FAITH` | number | `0` | 最近一次序列5成功结算的三类分项数值；Gameplay写入，UI按对应顶栏Tooltip显示 |
| `LOTM_TP_KNOWLEDGE_BONUS_SCIENCE` / `_CULTURE` / `_FAITH` | number | `0` | 序列5当前已通过原生平坦产出Modifier施加的三类每回合加成；Gameplay按目标20%只附加新旧差值，目标失效时归零，UI不得修改 |
| `LOTM_TP_PENDING_TECH_GIFT` / `LOTM_TP_PENDING_CIVIC_GIFT` | number | `0` | 序列0无当前选择时保留的一次赠送 |
| `LOTM_TP_TRADE_BRIDGE_SUPPORTED` | number | `0` | 假金币原生／Quick Deals结算技术门；资源275固定关闭待实测 |
| `LOTM_TP_CITY_TRANSFER_SUPPORTED` | number | `0/1` | 原生 `CityManager.TransferCity` 能力探针；运行时不可用时按钮保持隐藏 |
| `LOTM_TP_PARASITE_TARGET_OWNER` / `_CITY` | number | 空 | 序列4待寄生城市的原Owner与CityID；Gameplay写入，UI只读 |
| `LOTM_TP_PARASITE_TARGET_X` / `_Y` | number | 空 | 待寄生城市中心坐标快照，用于审计与失效诊断 |
| `LOTM_TP_PARASITE_START_TURN` / `_DUE_TURN` | number | 空 | 寄生开始回合与开始后5回合的到期回合 |
| `LOTM_TP_LAST_PARASITE_CITY` / `_TURN` | number | 空 | 最近一次确认易主成功的城市与回合；仅成功转移后写入 |
| `LOTM_TP_PRODUCTION_TRANSFER_SUPPORTED` | number | `0/1` | 生产队列进度接口运行时探针 |
| `LOTM_TP_ABILITY_DETACH_SUPPORTED` | number | `0/1` | Modifier完整卸载接口运行时探针 |
| `LOTM_TP_RELIGION_PRESSURE_SUPPORTED` | number | `0/1` | 城市宗教压力接口运行时探针 |

偷盗者控制面板与“寄生”按钮只读上述Property；目标、能力、最终方向、生产缓冲结算和城市指定都只提交`EXECUTE_SCRIPT`。序列6先在同步回合结算中累积生产缓冲，随后由活动本地玩家提交同步操作，并只在Gameplay命令处理器内调用`BuildQueue:AddProgress`；成功后才清零缓冲。假金币余额以`RESOURCE_LOTM_TP_FAKE_GOLD`库存为唯一真值。救援模式由`LOTM_RP_NORMAL_MODE` Criteria排除数据库／图标／UI，并由Lifecycle和偷盗者Gameplay再次拒绝。

Gameplay 内其他脚本可调用全局 `LOTM_RP_State.GetPublicState(playerID)` 获得同一组
只读快照。`LOTM_RP_SAVED_XP`、`LOTM_RP_HUNTER_XP_BASELINE`、
`LOTM_RP_SAVED_PROMOTIONS`、保存名称、Modifier挂载标志、项目解锁标志、教会周期、
真神教会与序列0资格、动态去重键及 Plot Property
、六档科技战力Modifier挂载标志
以及黑皇帝`LOTM_BE_CHAOS_I_UNLOCKED`、`LOTM_BE_CHAOS_II_UNLOCKED`、
`LOTM_BE_CORRUPTION_I_UNLOCKED`、`LOTM_BE_CORRUPTION_II_UNLOCKED`、
`LOTM_BE_FRENZY_I_UNLOCKED`、`LOTM_BE_CORRUPT_PROSPERITY_FOOD_ATTACHED`、
`LOTM_BE_ENTROPY_PRESSURE_ATTACHED`、`LOTM_BE_ENTROPY_PRESSURE_V2_ATTACHED`、
`LOTM_BE_ENTROPY_LOYALTY_ATTACHED`、`LOTM_BE_CHAOS_III_UNLOCKED`、
`LOTM_BE_CORRUPTION_III_UNLOCKED`、`LOTM_BE_FRENZY_II_UNLOCKED`、
`LOTM_BE_TRANSFORMATION_PROJECT_ATTACHED`、九个`LOTM_BE_TOMB_*_ATTACHED`槽位标志、
`LOTM_BE_MIGHT_STRENGTH_V2_ATTACHED`、`LOTM_BE_CIVILIAN_BUILDERS_V2_CLEANED`属于内部数据，不应显示为可编辑状态。详情页只能计算并显示本地玩家的
`digestA + digestB` 总进度，不能显示A/B分项，也不能自行
改变计数、冷却或项目状态。

燃烧视觉只读取当前可见地块的 `LOTM_RP_BURN_UNTIL`，并以
`LOTM_RP_BURN_REVISION` 触发载入/命令后的轻量 Lens 重建；两者均为同步内部
Property。过期清理由 Gameplay 完成，UI 不写 Plot 或 Game Property。

## LOTM_WORLD 随机事件状态（rc.81）

`LOTM_WORLD_State.lua` 是世界系统的 Gameplay 同步状态入口；随机数只通过 `Game.GetRandNum` 产生，UI 不提交或修改事件结果。

| Property | 作用域 | 含义 |
|---|---|---|
| `LOTM_WORLD_STATE_VERSION` | Game | 世界状态契约版本，rc.82 为 `2`；增加魔物唯一序号、活体索引、工坊冷却、奖励账本与刷怪诊断 |
| `LOTM_WORLD_PLAYER_TURN` | Player | 该玩家已结算的玩家回合计数 |
| `LOTM_WORLD_PLAYER_TURN_SETTLED_GAME_TURN` | Player | 当前世界回合去重标记，防止读档／重连重复抽取 |
| `LOTM_WORLD_EVENTS_STARTED` | Player | 首名途径持有者已真实诞生，随机事件计时已启动 |
| `LOTM_WORLD_EVENT_NEXT_TURN` | Player | 下一次触发的玩家回合 |
| `LOTM_WORLD_EVENT_BAG` / `LOTM_WORLD_EVENT_BAG_INDEX` | Player | 已洗牌的 `GGBB` 袋及当前索引 |
| `LOTM_WORLD_EVENT_LAST_1` / `LOTM_WORLD_EVENT_LAST_2` | Player | 跨袋连续类型防护 |
| `LOTM_WORLD_EVENT_KIND` / `TARGET` / `TRIGGER_TURN` / `SERIAL` | Player | 最近一次事件的只读摘要与通知去重序号 |
| `LOTM_WORLD_NOTIFICATION_DELIVERED_SERIAL` | Player | 已成功提交右侧途径标志通知的最新事件序号；旧 rc.81 缺失时补发一次 |

## LOTM_WORLD 失控魔物状态（rc.82）

| Key | Owner | Contract |
|---|---|---|
| `LOTM_WORLD_MONSTER_NEXT_SERIAL` | Game | 单调递增魔物唯一序号；不得用可能复用的引擎单位ID替代 |
| `LOTM_WORLD_MONSTER:<serial>:*` | Game | 活体、引擎所有者／单位ID、等级、来源、冻结B及奖励去重账本 |
| `LOTM_WORLD_MONSTER_ENGINE:<owner>:<unit>` | Game | 战斗和移除事件到唯一序号的同步索引 |
| `LOTM_WORLD_WORKSHOP_MONSTER_SERIAL` | Plot | 来源工坊当前活体唯一序号；0表示无活体 |
| `LOTM_WORLD_WORKSHOP_MONSTER_COOLDOWN_UNTIL` | Plot | 魔物死亡或移除后的世界回合冷却截止值 |
| `LOTM_WORLD_MONSTER_TIER/ SERIAL / SOURCE_WORKSHOP` | Unit | 魔物等级、唯一序号与来源工坊；随存档保存 |
| `LOTM_WORLD_MONSTER_BASELINE / TARGET_STRENGTH / TARGET_MOVES` | Unit | 出生时冻结的B、目标战力与移动力 |
| `LOTM_WORLD_MONSTER_*CHECKS / ROLLS / HITS / SPAWNED / SUPPRESSED_*` | Plot/Game | 工坊及等级聚合诊断，用于核对普通／额外刷兵和魔物概率 |
| `LOTM_WORLD_EFFECT_VISIBILITY_REPAIR87` | Player | 资源版本87已对最近一次“已提示但已过期”的事件执行至多一次5回合补偿 |
| `LOTM_HOLDER_GOOD_STATE_UNTIL` | Player | 持有者 `+5` 战力、`+1` 移动的截止回合 |
| `LOTM_HOLDER_UNSTABLE_STATE_UNTIL` | Player | 持有者 `-5` 战力、`-1` 移动（最低 1）的截止回合 |
| `LOTM_ARTIFACT_SATISFIED_UNTIL_<instance>` | Player | 指定封印物实例只启用正面效果的截止回合 |
| `LOTM_ARTIFACT_UNCONTROLLED_UNTIL_<instance>` | Player | 指定封印物实例只启用负面效果的截止回合 |
| `LOTM_RP_ART_LETTER_WAR_GOLD_ACTIVE` | Player | 密信独立原生 `+50` 每回合金币 Modifier 当前是否已启用 |
| `LOTM_RP_ART_LETTER_PEACE_PENALTY_ACTIVE` | Player | 密信独立 `-25%` 城市金币倍率 Modifier 当前是否已启用 |
| `LOTM_WORLD_PURCHASED_POTION_SEQUENCE` | Player | 已付款、等待消化完成的唯一魔药对应当前序列；缺失表示没有资格 |
| `LOTM_WORLD_PURCHASED_POTION_PROJECT` | Player | 已付款魔药对应的精确项目类型，仅用于权威核验和旧队列迁移 |
| `LOTM_WORLD_PURCHASED_POTION_SERIAL` | Player | 已付款聚会报价序号，用于重放保护及清理确认 |
| `LOTM_WORLD_GOODY_POTION_CLEAR_PROJECT` | Player | 已购魔药在消化满并直升后，需从旧存档城市队列移除的精确项目类型 |
| `LOTM_WORLD_GOODY_POTION_CLEAR_SERIAL` | Player | 已购魔药直升后的清队列确认序号；UI只据此提交原生同步 `REMOVE_AT` |

封印物状态优先级为“失控 > 满意 > 正常”；只有当实例仍在九个装备槽时才发放对应正／负租约，卸下不删除截止回合。持有者能力根据 Player Property 恢复到当前英雄，死亡时计时仍继续。
