# 资源292：单机下一步研发审核与最小修复

输入诊断包：`Civ6_LOTM_Diagnostics_20260906_102953.zip`（2026-09-06）。

## 结论

### 一个文明没有被攻击

`Lua.log` 中，多个疯狂者在世界回合约 70 附近将目标锁为 `owner=47, city=65536, plot=568`，随后反复记录：

```text
action ... reason=NO_PLOT attack=true targetKind=AI_CITY targetOwner=47 targetCity=65536 destination=568
```

`LOTM_WORLD_Monsters.lua` 的 `LockedTarget` 只验证城市对象仍存在；`MoveToward` 在目标没有合法接近地块时返回 `NO_PLOT`，而 `Act` 原先没有清理这个仍“有效”的城市锁。因此这些单位每回合继续尝试地块568，造成该文明实际永远不被攻击。该问题与刷新概率、外部模组无关。

资源292仅在单机分支对 `NO_PLOT + AI_CITY` 释放锁；联机分支完全不变。

### 序列者战斗力面板标消失

当前 UI 替换入口在 `UnitAddedToMap` 立即读取 `LOTM_PP_WORKSHOP_SEQUENCE`。普通模式序列持有者的属性由 Gameplay 后续写入；属性尚未到达时，旧逻辑把它当成普通单位并返回成功，不再调用 `SetFlagUnitEmblem`。因此地图／战斗力面板显示原版单位标，表现为序列者标记消失。

资源292只针对 `UNIT_LOTM_PP_PATH_HOLDER` 建立事件级（最多6次）UI重试，在 `GameCoreEventPublishComplete`、读档完成和本地回合开始触发；不扫描全图，不改变 Gameplay、属性或联机队列。

## 变更文件

- `Scripts/LOTM_WORLD_Monsters.lua`：单机 stale city lock recovery。
- `UI/LOTM_PP_UnitFlagManager.lua`：单机 sequence-holder flag retry。
- 版本／发布元数据升级为 `0.1.0-rc.260`／资源292。

## 验收边界

静态、语法、构建和哈希检查只能证明包一致。需在新单机救援局确认：owner47（或同类无接近地块目标）下一回合会释放并改攻其他文明；新生成及读档后的序列者在战斗力面板均显示途径标记。联机资源291行为本轮未修改，仍按其既有双客户端清单单独验收。
