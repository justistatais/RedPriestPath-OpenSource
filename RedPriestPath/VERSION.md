# Version

- Mod ID: `{7E4D8D9C-0C96-4B9C-A3D4-6A1E6B19D970}`
- Semantic version: `0.1.0-rc.403`
- .modinfo resource version: `435`
- Ruleset: `RULESET_EXPANSION_2`
- State version: `LOTM_RP_STATE_VERSION=36`
- Extraordinary World state version: `LOTM_WORLD_STATE_VERSION=6`
- AI cult state version: `LOTM_CULT_STATE_VERSION=4`
- Rescue Phase 2 state version: `LOTM_RESCUE_PHASE2A_VERSION=11`
- Rescue Phase 3 state version: `LOTM_RESCUE_PHASE3_VERSION=12`
- Rescue Phase 4 state version: `LOTM_RESCUE_PHASE4_VERSION=5`
- Rescue difficulty state version: `LOTM_RESCUE_DIFFICULTY_VERSION=3`
- Rescue Phase 5 state version: `LOTM_RESCUE_PHASE5_VERSION=26`
- Rescue Phase 6 state version: `LOTM_RESCUE_PHASE6_VERSION=2`
- Rescue Phase 7 state version: `LOTM_RESCUE_PHASE7_VERSION=5`
- Rescue Phase 8 state version: `LOTM_RESCUE_PHASE8_VERSION=7`
- Rescue Phase 9 state version: `LOTM_RESCUE_PHASE9_VERSION=9`
- Rescue Phase 9 digestion version: `LOTM_RESCUE_PHASE9_DIGESTION_VERSION=2`
- Rescue governor state version: `LOTM_RESCUE_STAR_STATE_VERSION=1`; unit-ledger migration `1`.
- Rescue artifact runtime version: `VERSION=4` in `LOTM_RESCUE_Artifacts.lua`
- Rescue Phase 10A measurement version: `LOTM_RESCUE_PHASE10A_VERSION=6`
- Rescue Phase 10 final-battle version: `LOTM_RESCUE_PHASE10_VERSION=40`
- Rescue synchronized action helper version: `9`
- Multiplayer route: published rc.241/resource-273 four-context baseline plus an explicit post-rc.241 feature delta (`LOTM_MP_TurnSync.VERSION=241` compatibility surface; no unified dispatcher)
- Current single-player turn dispatcher source version: `7`
- Workshop registry version: `LOTM_PP_WORKSHOP_REGISTRY_VERSION=3`
- Active monster index version: `CURRENT_ACTIVE_MONSTER_INDEX_VERSION=1`
- Project qualification migration: `LOTM_PATH_PROJECT_GATE_VERSION=1`; unlock repair: `5`
- Rescue barbarian cleanup migration: `LOTM_RESCUE_BARBARIAN_CLEANUP_VERSION=2`
- Rescue runtime event bridge: `5`; early-seal migration: `1`
- Scope: Resource 411 adds 16 player pathway models, four visual tiers, native promotion-driven attachment visibility, and an independent synchronized cosmetic updater. Native in-game and multiplayer validation remain pending.
- Previous scope: Resource 410 corrects native UV V coordinates for the astral gate and four sigils. Final-FGX UV sampling is checked against cooked pixels, ground clearance is slightly increased and visual culling radius is separated from the physical footprint. Gameplay and texture binaries are unchanged. User performs in-game validation.
- Previous scope: Resource 409 adds four oversized rotating ground sigils, an Astral Descent star gate and a V2 cosmetic CENTER selector. Native material scroll drives the animation; original church bodies and unit binaries are preserved. Two-platform Cooker and offline tests do not constitute in-game validation.
- Previous scope: Resource 408 restores repaired character and holy-city art with complete SHARED_DATA dependencies. Cities use native static three-UV layouts and 27 bounded geometry resources, normalized TBN and no automatic LOD; all source faces are retained. Offline validation is not a game-rendering verdict. Gameplay remains unchanged.
- Previous scope: Resource 407 quarantines both experimental art packs after resource406 live mesh stretching/black-map failure. Their actions and release files are removed; prior art and all gameplay remain intact. Original source and failed builds are preserved. Recovery visuals remain unverified; new models are not fixed.
- Previous scope: Resource 406 repairs Saint/Angel shader inputs and false emission, restores full city materials, and binds the three holy cities through direct BuildingVariants. Resource405 logs confirmed markers/packages loaded while visuals failed. Gameplay and geometry are unchanged; repaired in-game rendering and multiplayer remain unverified.
- Previous scope: Resource 405 integrates three original church holy cities through isolated rescue-only hidden building selectors and a synchronized, verified, retryable installation receipt. Windows/macOS art is cooked; city rendering and multiplayer remain unverified.
- Holy city art receipt: `LOTM_RESCUE_HOLY_CITY_ART_IDENTITY_V1`; version `1`.
- Previous scope: Resource 404 integrates seven elemental V4 models, Saint V4 and Angel V1 into 15 rescue unit art bindings. Native rigs, emissive light-wing/halo geometry and UV light flow are packaged; gameplay behavior is unchanged. Game and multiplayer visual verification remains pending.
- Previous scope: Resource 403 honors native ownership of an already purchased Story promotion without revoking it for a missing sibling prerequisite. Adds effective-turn clock diagnostics. Resource 402 production cache repair remains unchanged and has live confirmation: 1315.59765625 -> 15.59765625, VERIFIED. Story triggering and multiplayer still require live verification.
- Previous scope: Resource 393 disables the normal-mode test combat button and command feature flag. Comics are rescue-only through the UI action criterion and runtime guards: normal pathway details have no review button, the launcher skips the prologue, and no automatic/manual ending comic can open or acknowledge itself. Existing rescue comic behavior and frozen rescue gameplay remain unchanged.
- Verification boundary: static checks and hashes do not replace in-game or multiplayer verification.
- 双客户端均待实测。

- Resource 412 scope: independent session ownership snapshot receipts and production audit commands; turn-scoped retries, explicit UI stages, and unchanged Story/production/model rules. Current old-save Story counter remains 3/7. UI-to-Gameplay simulation passes; live and multiplayer verification pending.

## Resource 413 scope
- Reveal the Justice Story add-in context that native InGame loads hidden. Preserve resource412 gameplay and production correction, and resource411 models.
- Regression covers hidden parent context, pending-opportunity reload, single completion and expiry; native rendering remains user-tested.

## Resource 414 scope
- Full rectangular Story panel background encloses all text and the button.
- Allow original production to advance between capture and completion; preserve its queue membership and progress. One-use, ownership, current-turn and legal target guards remain.

## Resource 415 scope
- One-click immediate Story completion of the selected eligible production item, independent of legacy capture/queue membership.
- Normalize native queue row identifiers, show actionable click feedback, and log submit/execute.

## Resource 416 scope
- Replace Story CanProduce gate with Gameplay CurrentlyBuilding identity validation before immediate FinishProgress.
- Regression denies UI-only CanProduce and checks empty/changed queues plus native project type-name resolution.

## Resource 417 scope
- Star player-owned diplomatic visibility and empire spy defense use reversible resource leases; add own counterspy +2.
- Interrogation awards a synchronized random 300 science or culture per captured enemy spy case.
- Governor snapshots use acknowledged retries and native promotion ownership. New effects require live validation.

## Resource 418 scope
- Rearm governor snapshot retries after load readiness; observe native visibility and one-time modifier/requirement state. Resource417 effect definitions are unchanged pending runtime evidence.

## Resource 419 scope
- Replace inactive custom diplomatic visibility source with base-game journalism source, using a separate reversible lease. Retire old custom source lease on synchronization. Native outcome and stacking with the actual Great Merchant remain user-tested.

## Resource 420 scope

Normal-mode Time Worm acquired civilization abilities can be permanently retired through a synchronized confirmation, native resource gates and checked receipts. Native civilization/leader roots and other retained shared roots are preserved. Existing one-time rewards are not reversed. Old-save native gate availability is checked before changes; game verification remains pending. Justice uses native promotion ownership, preserves positive holder states during counseling, and counts Oracle writer points while excluding pillaged districts from Salon base points. Other external modifier sources for Salon remain an explicit coverage gap. Rescue gameplay is frozen.

## Resource 421 scope

Magician/Fors is redrawn with the built-in image generator; Star/Leonard uses the exact user-selected portrait supplied on 2026-09-29. Fors has a warm study and a raised magical doorway gesture; Leonard is a refined poet with notebook and quill on a cool moonlit garden terrace. Two source PNGs and 16 DDS exports updated through the existing art builder, including circular city-banner fill/slot icons. Governor definitions, gameplay and UI behavior are unchanged apart from release stamps. In-game rendering remains user-tested; all resource420 gameplay verification boundaries remain open.

- Resource 422 scope: normal Red Priest four-number balance, host-configured locked Easy/Hard/Insane AI cult self-bonuses with exclusive native owner gates, upkeep percentage refund and once-per-own-turn Hanged healing; incremental Flesh Puppet fallback and a version-gated repair. Game and dual-client acceptance pending.
- AI cult difficulty version: `LOTM_CULT_DIFFICULTY_VERSION=1`; Flesh Puppet index version: `LOTM_CULT_HANGED_PUPPET_INDEX_VERSION=1`. Original cult state remains version 4.


## Resource 423 scope

- Repair normal-mode cult military eligibility through explicit immutable combat-unit type bindings, excluding civilians and support.
- Versioned V2 military parent/child IDs and per-token receipts repair rc390 saves without reattaching economy. Existing/future units use the native collection and current exclusive stage resource.
- Fresh-save legacy military parents are gated inactive; old serialized nonmatching filters are left untouched. Difficulty/stage numbers and Chained territory requirements stay unchanged.
- Gameplay changes remain on synchronized startup/turn events; normal Criteria and rescue runtime guards remain. Native military recovery, old-save reload and multiplayer require new in-game evidence.

## Resource 424 scope

Normal-mode gods: Fool/Night effects remain, with one capital animation per awarded blessing. Storm blessings grant one persistent targeting charge each. A separate native WMD copies the normal nuclear device's damage flags and radius 1, with FalloutDuration=0 and Maintenance=0. Synced preparation/target/settlement/cancellation receipts; vanilla WorldInput owns the native strike and confirmation. Charges are consumed only after the dedicated native inventory is consumed. Existing active storm buffs migrate once; expired old buffs do not grant new charges. The badge is left of the notification column. Three transparent animated world anchors use the supplied scenes. No native single-player or multiplayer pass claimed by offline checks.


## Resource 425 scope — TEMPORARY DEBUG BUILD

User-requested normal-mode Storm testing: the marked `STORM_DEBUG_UNLIMITED=true;` assignment in `Scripts/LOTM_GodBlessings.lua` enables the button without any blessing and unlimited casts. Comment that single assignment to restore the default false, then regenerate the normal Gameplay bundle and publish/install a new resource. The synchronized startup flag drives the UI infinity count and DEBUG tooltip. Per-cast debug receipts prevent earned-charge consumption, including a pending debug cast loaded after disabling. Real blessing grants, native targeting/damage/fallout definitions, Night/Fool effects and rescue behavior remain unchanged. Actual strike/rendering and multiplayer still require game evidence.


## Resource 426 scope — UI LOAD REPAIR, TEMPORARY DEBUG RETAINED

Actual resource425 Modding.log reports that LOTM_STORM_BLESSING_UI and LOTM_GOD_BLESSING_FX_UI lack the required Context property, aborting enabled-component application and rolling back the database before Gameplay begins. Both now declare Context=InGame, following existing add-ins. The release UI validator rejects any missing or empty add-in Context; the blessing regression reproduces both real faulty declarations. Storm unlimited-debug behavior, earned charges, targeting/damage, capital animations and rescue gameplay remain unchanged. Native loading after this repair, actual strike effects and multiplayer still require new in-game evidence.

## Resource 427 scope — STORM BUTTON VISIBILITY AND USER POSITION

The user's resource426 screenshot and native logs confirm successful loading but no visible Storm button. Firaxis InGame.lua creates add-ins with isHidden=true; both new blessing add-ins now explicitly show their parent ContextPtr only in normal mode, following the existing launch/HUD implementation. The Storm badge center is (1820,752) at 1920x1080, matching the user's red circle left of the event column, and moves with viewport resize. Existing unlimited-debug, synchronized gameplay, native damage/no-fallout definitions, earned charges and all art remain unchanged. Hidden-parent, resize and rescue-hide regression coverage added. Actual resource427 display, targeting, damage/animation and multiplayer remain pending native evidence.

## Resource 428 scope — NATIVE CONFIRMED LAUNCH AND LIGHTNING UNIT FLAG

The user and resource427 logs confirm the visible badge, native targeting, temporary carrier creation and cancellation. The user reports a confirmation dialog followed by no launch. The extension reversed Firaxis WMDStrike(plot,unit,eWMD) arguments; it now accepts and delegates the native order. Regression executes the installed Firaxis confirmation and launch functions, covering explicit confirmation, native rejection, war confirmation, stale carrier and unchanged ordinary nuclear delivery. The carrier flag reuses the native Power lightning glyph at 22/32px, so civilization tint no longer darkens the colored badge; its portrait and the ability badge retain the supplied artwork. Target entry logs the native candidate count. No target restrictions, Gameplay SQL, synchronized state or unlimited-debug rules changed. Actual resource428 launch/damage/no-fallout/rendering and multiplayer remain pending native evidence.


## rc.397 / resource429 — 城市直接风暴与V4大型云群

普通模式风暴改为原版城市ICBM投放，不再创建/出动载体单位。首都标识预留城市，同步Gameplay在首都半径3内复用现有导弹井，或于无设施/地貌/资源的己方空地创建临时投放源；成功、取消和跨回合清理。旧已准备的载体按ID/类型/投放序号清理，已消耗的旧投放仍结算一次。确认框捕获投放序号和源修订，防止旧弹窗误放下一次调试技能。

新V4动画完整216帧/24fps/9秒，1大4小云群，768×512显示，按模型地面投影对齐目标；原动画及全部历史美术保留。普通核弹损伤开关/半径1/FalloutDuration=0保持，城市投放距离999；临时无限DEBUG标注开关保持。离线/安装检查与游戏实测分别记录，城市原生投放、五片云群观感、实际损伤/无辐射和联机仍待用户实测。救赎封存逻辑保持。

## rc.398 / resource430 — 选点后直接风暴轰击

普通模式风暴已移除城市/单位核武指令、临时发射场、库存及导弹动画。自有选点/半径1预览/确认仅提交同步EXECUTE_SCRIPT，Gameplay按单位、区域城防、建筑、设施/道路及地块劳动人口直接结算，再发布现有216帧V4雷暴。无新增核辐射；无限DEBUG中文开关保持。失败前置检查/绝对损伤端点/持久分步回执防止重试或读档重复伤害；完成后才扣正式次数。旧载体/临时发射场按已存身份一次清理，既有普通导弹井保护。

按原版百科公开规则编写损伤流程；原生核弹内部C++未开放独立Lua引爆API，不能把脚本或替身通过写成逐项与原生核弹数值等价已验证。核防护直挂能力按实际Blast参数读取；其它来源核防护、资源/特殊单位与原版逐项对照、目标表现、旧档和双端仍待实机。本版不触发原生核投放统计/防空拦截/紧急事件。美术/既有祝福/救赎封存保持。

## rc.399 / resource431 — 风暴确认文案与选点标题

确认说明按用户要求显示两行：“在此处释放闪电风暴？”和“风暴之主将降下伟力击杀范围内敌人。”，中英文包保持同一结构。仅在普通风暴瞄准期间将原版ModalLensPanel的LensText改为闪电风暴；离开瞄准时恢复原标题，若原生已更新为其它透镜标题则保留该标题。无新增上下文替换或Gameplay更改，430直接损伤、V4、无限DEBUG和救赎行为保持。实际游戏内文字、换行与退出恢复仍待用户载入；此前伤害等量边界继续。

## rc.400 / resource432 — 密集雷击帧结算风暴伤害

风暴确认后只发布V4动画和持久待命中阶段；在第99帧（零基98，24fps约4.083秒）画出成片落雷后，仅拥有者UI提交同步LOTM_Storm_Impact。Gameplay校验施法/特效/目标/展示帧，重新快照范围内实际对象及战争许可，才执行既有损伤、扣次数和FIRED回执。不在渲染回调直接修改权威状态，不使用Gameplay本机时间。等待期间禁止取消/重复准备；跨回合和读档不提前结算，读档只重播未命中的风暴。卡帧先显示密集打击帧，迟延请求按同一身份重试；部分损伤仍按绝对端点续做，完成不再重复播放动画。

保留431确认说明两行与闪电风暴标题、V4尺寸/素材、无限DEBUG、零新增辐射、黑夜/愚者及救赎封存。Gameplay模块VERSION=4，旧delivery3及旧部分计划兼容。用户已反馈431实际伤害发生于动画开头；432实际帧时机、网络呈现、旧档和原核弹数值等量仍待实机，不将替身测试等同原生通过。

## Resource 433 scope

2026-10-07，rc.401：正义与魔术师既有技能接入救赎，普通星星树保持。救赎独立C3案件档案（每个己方领土敌军击杀随机300科技/文化）、C4红手套巡查（普通侦察持续+1移动及移动完成一圈临时视野）、D隐秘世界（双分支AND，全图普通视野）及中英文Selected生成。Star state/one-time unit ledger version=1；普通存档不迁移，当前已发布救赎无旧总督头衔可映射。救赎其它封存文件保持，原风暴432行为保持。专项/数据库/构建和安装记录另见迁移报告；单机真实与双端/重连验证待用户自行载入，不能据离线测试宣称通过。


## Resource 434 scope

2026-10-07，rc.402：风暴直接技能接入救赎，GodBlessings模块VERSION=5，Delivery/session版本3保持。普通核弹步骤生成前识别外神本体，独立每次最多20伤害，眷属与其他目标沿用现有核弹流程；旧未完成UNIT计划先转换，单位类型/阶段epoch/每投放已伤害回执防止误杀与重复。Phase10新增限定同步接口，原战斗代码字节保持且封存检查精确验证新增块。救赎原风暴祝福增益保持，FULL/HALF奖励一次补发一发，现有∞DEBUG继续；黑夜愚者特效仍普通。V4/约4.083秒密集雷击/零新增辐射保持。详见RESCUE_STORM_REPORT.md；实际HP、原生阶段/检查点、保存重载和双端均待实测。


## Resource 435 scope
- Production Lightning Storm uses earned, persistent charges in both modes. Redemption 10/15-envoy storm blessings each grant one skill use, replacing their temporary naval/economic/healing bundle; artifact chances and other church rewards remain unchanged.
- Migrate the old temporary storm bundle once with its existing OFF members, retain grant/spend receipts, and stop unlimited testing. A previously accepted test windup/partial impact can finish once; unconfirmed test aiming is cancelled.
- Aiming and cancellation are immediate local presentation. Only target confirmation submits a synchronized prepare-and-fire operation, preserving charge, turn, serial, visibility, diplomacy and stale-popup checks.
- Remove aiming explanation; Cancel Aiming is 280x56 with FontNormal24. Redemption church detail shows the saved charge count.
- Existing V4 impact cue, Outer God 20-damage cap, other blast endpoints and art/SQL are unchanged. Native large-save latency, upgrade, UI layout and multiplayer still require user validation.
