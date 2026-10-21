# 资源279｜救援旧档联机OOS复查

## 证据范围

- 最新会话：2026-08-29 23:30～23:47；`net_message_debug.log`约13.8 MB、`Lua.log`约0.55 MB、`Modding.log`约0.70 MB。
- 按固定事件范围检查首次`StartGameSyncCheck()`及其首批AutoArchive差异，没有整份载入大型日志。
- 本局明确为救援模式：Player Property含三教会、Phase10A及救援封印物状态。用户反馈正常模式联机未复现，本报告不把救援结论外推为正常模式故障。

## 首个可识别差异

23:30:49开始首次同步检查，23:30:51 Player 0的`m_kProperties`首先报告OOS。两端绝大多数命名Property一致，明确差异为：

- 一端`QD_SELLABLE_DEALS`／`QD_BUYABLE_DEALS`为空Map；
- 另一端两项包含玩家本地扫描得到的可买／可卖交易Map。

资源278的兼容层已经实际加载，但旧实现先调用Quick Deals原`GetCachedDeals`读取存档值，只替换未来`SetCachedDeals`。因此它阻止了新写入，却没有清除保存文件中已经不同的同步Property，第一次同步检查仍会直接失败。

## 外部代码对照

- Quick Deals `gameplay/qd_cachemanager.lua`按本地玩家读取，并以`Player:SetProperty`写`QD_*`；这是把客户端UI缓存写入同步状态的直接来源。
- Quick Deals `ui/qd_launchbutton.lua`保存的是`ExposedMembers.QD.CacheManager`表引用，再调用其`GetCachedDeals/SetCachedDeals`；原表方法可被兼容层替换，但若外部脚本重建表，必须在载入后重新安装包装。
- 海克斯大乱斗的可同步选择使用UI `EXECUTE_SCRIPT`提交、Gameplay验证及修改状态；红祭司继续遵循相同权威边界，未复制无明确许可证代码。
- 资源种植器的消耗次数由Gameplay命令后`ChangeAbilityCount`写入；海克斯大乱斗通过玩家Modifier授予无视地形能力。两者都不是红祭司能力。

## 单位Ability差异映射

首次快照中Player 1的四个单位在`m_aiAbilitiesPossessed`出现相同位置交换：

| 数组位置 | 本机DebugGameplay映射 |
|---:|---|
| 314 | `ABILITY_BP_CONSUMED_CHARGE_1` |
| 315 | `ABILITY_BP_CONSUMED_CHARGE_2` |
| 488 | `ABILITY_NW_UNBOUND_ARMY` |
| 489 | `ABILITY_NW_UNBOUND_PEOPLE` |

这些能力分别属于Workshop `3758337710`与`3765281534`。当前证据不能区分“此前OOS重载后单位状态已分叉”和“两端UnitAbilities加载索引不同”，所以资源279不擅自更改外部模组；新增只读索引指纹日志，下一次双端日志可直接判别。

## 资源279修复

- 网络多人且Quick Deals实际启用时，按PlayerID 0～63清除所有现存`QD_SELLABLE_DEALS`／`QD_BUYABLE_DEALS`；不读取客户端旧缓存。
- 脚本载入立即执行一次，`LoadGameViewStateDone`与`LoadScreenClose`后重新安装本地缓存包装，并在最低存活主要文明的同步`PlayerTurnStarted`锚点再次复核。
- 清理只在Property非空时写`nil`，稳定排序、不使用本地玩家、不推进随机数。
- Quick Deals缺失时Action不加载；单机即刻退出。正常模式玩法、救援数值、失控魔物和外部Workshop文件均未修改。

## 验收边界

- 静态、专项、数据库、构建与哈希检查只能证明候选结构，不等于双客户端通过。
- 旧档首次进入时两端Lua应出现`cache guard loaded`与旧值清理日志；第一次同步快照不应再含`QD_*`。
- 若仍有Ability OOS，先比较两端`[LOTM][MPFingerprint] UnitAbilities`四项Index。Index不同属于双方数据库/模组加载集合问题；Index相同而单位计数不同，才继续按存档分叉与外部Gameplay写入链追踪。
