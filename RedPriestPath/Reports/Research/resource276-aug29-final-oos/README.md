# 2026-08-29 新一局联机 OOS 最终定因

## 结论

本局 OOS 的首个可归因分叉来自本 MOD 的暴走工坊分类链，不是外交系统、Quick Deals，也不是上一局的 `MAO_ActiveTradeRoute*`。

`LOTM_PP_Workshops.lua` 在 `Events.ImprovementAddedToMap` 回调中调用 `Classify`，而 `Classify` 直接消耗全局同步随机数：先进行工坊判定，成功后又继续随机等级和途径。联机两端收到／处理 Improvement 事件的时机或顺序不一致时，就会以不同顺序和次数调用 `Game.GetRandNum`，继而使 GameCore 同步随机流永久错位。该分叉随后扩散到救援营地、魔物、单位、可见性、外交与 AI 档案。

这是代码层面的联机确定性缺陷；不需要假设 Quick Deals、MAO 或外交系统先出错才能解释本局证据。

## 最新会话边界

- 日志时间：2026-08-29 10:24～10:36。
- `NetGameSyncCheck` 共 4 次；前三次产生 3280 个 AutoArchive mismatch，并各触发一次完整 Game State 重载。
- 第四次检查出现在第三次重载后；随后 10:36 连接结束。
- 首次 mismatch 在第 1 个世界回合结束时出现，不能用中后期战斗或魔物死亡解释。

## 首个同步快照

首次 Game::Instance 快照给出：

- 本地同步 RNG：seed `669247939`，callCount `5356`。
- 远端同步 RNG：seed `3306659576`，callCount `5333`。
- 到第一次同步检查时，两端已经相差 23 次同步随机调用。

同一快照的 Game Property 共有 692／694 个键，只有 3 项不同。其中唯一可识别的命名键就是本 MOD 的工坊登记表：

- 本地 `LOTM_PP_WORKSHOP_REGISTRY_PLOTS`：20 个地块。
- 远端 `LOTM_PP_WORKSHOP_REGISTRY_PLOTS`：18 个地块。
- 两端列表不仅数量不同，具体工坊地块也不同。

与此同时，`LOTM_RESCUE_PHASE5_BONUS_CAMP_PLOTS` 在两端仍完全相同，均为：

`4621,8286,7773,6999,5412,8062,5606,2457,2187,3707`

这排除了“Phase5 先选出了不同的十个营地”这一解释。营地创建结果先一致，随后同一批营地的工坊分类才分叉。

## 与源码的闭环

关键调用链位于：

1. `LOTM_RESCUE_Phase5.TrySupplementCamps` 在最低存活主要文明的同步世界回合回调中创建十个营地。
2. `LOTM_PP_Workshops.Initialize` 注册 `Events.ImprovementAddedToMap`，事件到达时调用 `Classify`。
3. `Classify` 对每个尚未分类的营地调用 `Game.GetRandNum(100, "LOTM PP workshop classification")`。
4. 判为工坊后又分别调用 `RollLevel` 和 `RollPath`，因此不同分类结果还会改变后续随机调用次数。
5. `RegisterWorkshopPlot` 把结果写入权威 `LOTM_PP_WORKSHOP_REGISTRY_PLOTS`。

本地 Lua 日志也复现了这一顺序：Phase5 先记录十个相同营地，工坊 `classified plot=...` 日志在之后批量出现。本地最终得到 20 个工坊；远端同步快照保存了另一组 18 个工坊。

第二次同步检查时，后果已经扩散：

- 同步 RNG 调用数变为 5722／5687，差 35 次。
- 两端下一批 `LOTM_RESCUE_PHASE5_BONUS_CAMP_PLOTS` 已完全不同。
- 本地周期魔物结算为 6 次成功生成，远端为 4 次成功生成；生成来源、序列、等级和净化贡献账本均不同。

所以 PlayerDiplomacy 虽然在 AutoArchive 输出顺序中最先显示，但它是随机流／地图对象分叉后的受害档案，不是首因。

## 版本与加载来源

- 本局实际从 Steam Workshop `3780342356` 加载本 MOD，而不是已临时停用的本地 modinfo。
- 当前机器上源码、Workshop 副本和本地安装副本的三个相关脚本 SHA-256 完全一致：`LOTM_PP_Workshops.lua`、`LOTM_RESCUE_Phase5.lua`、`LOTM_WORLD_Monsters.lua`。
- Workshop modinfo 标记资源 273；源码候选 modinfo 为资源 275，但本次根因涉及的三个脚本内容一致。
- 单侧日志不能证明另一台机器的完整 Manifest，但本次分叉机制本身已经是确定性违规，双端异版不是成立此根因的必要条件。

## 失控魔物

- Phase5 和 Monsters 源码没有 `Network.IsMultiplayer`／多人降档分支。
- 本局仍使用单机相同的第一时期参数：工坊概率 80%、每回合 6 次尝试、全图上限 40、同一生成和 AI 行动链。
- 本地可见日志共记录 14 次生成、4 次 release／奖励；其中多次是 OOS 重载后的不同世界状态，不能相加当成一条连续战局的唯一存量。
- 本局魔物数量差异是 OOS 后两端随机流和工坊集合不同的结果，不是联机模式主动少刷。按用户要求，不再单独调整魔物密度或生存数值。

## 后续修复边界

本轮只定因，没有修改玩法。修复时必须移除“本地事件回调直接消耗同步 RNG”这一结构：工坊分类需要进入单一世界回合权威批次并按 PlotIndex 稳定排序，或改用不推进全局 RNG 的稳定判定；同时要保证新增／移除工坊登记是可重放、幂等和增量的。修复完成前，当前救援高流量营地链不能标记为多人通过。

## rc.244／资源276修复结果

- `LOTM_PP_Workshops.lua`中的三处`Game.GetRandNum`已经全部移除。
- `ClassificationSeed`从双方共同的`GAME_SYNC_RANDOM_SEED`与地图`RANDOM_SEED`计算会话内稳定种子；`StableClassificationRoll`再混合PlotIndex和`CLASSIFICATION/LEVEL/PATH:<level>`通道。
- 每个地块的工坊、等级、途径结果不读取或推进共享随机状态；事件到达顺序只影响日志顺序。
- 新分类写`LOTM_PP_WORKSHOP_DETERMINISTIC_VERSION=1`，日志追加`roll`与`deterministicVersion`，便于双端逐地块比较。
- 工坊登记版本升至2。迁移全扫仍只在版本变化时执行，已分类旧档不重抽；增量注册、移除和覆盖索引保持原结构。
- Phase5营地与魔物所有数值未修改。

静态回归把同一PlotIndex集合分别按正序、逆序、奇偶交错执行，逐地块三元结果一致；完整发布构建通过。该结果只证明候选结构，仍需两套真实客户端验证`m_kSyncRandom`、工坊登记、后续营地／魔物及AutoArchive完全一致。
