# 资源280／8月30日普通模式联机 OOS 取证

## 结论

本机日志显示本局普通模式在第一回合结束即发生 OOS，并在之后反复检查。首个可识别差异是 `Player.m_kProperties` 中两侧各自出现的未知 `TypedVariantMap` 属性键；红祭司 `LOTM_*` 与 Quick Deals `QD_*` 在该次差异中没有显示为不一致。因此当前证据更支持外部模组同步 Player Property 或双方实际模组文件集不一致，不能把 Quick Deals 或红祭司单独定为首因。

## 时间线

- 日志：`C:/Users/20594/AppData/Local/Firaxis Games/Sid Meier's Civilization VI/Logs/net_message_debug.log`
- 10:11:04：首次 `StartGameSyncCheck()`。
- 10:11:05：首次 `Player 0 ... Variable Out Of Sync : m_kProperties`，随后大量玩家档案 mismatch。
- 10:11:52～10:57:01：继续 29 次同步检查（总计 30 次），后续扩散到单位能力与 AI 评估档案。

## 首次差异

首次 Player 0 快照两侧均有相同的主要 `LOTM_*` 值；未见 `QD_SELLABLE_DEALS` 或 `QD_BUYABLE_DEALS` 的差异。两侧各自多出的键为：

```text
Unknown Variant Key(59168906)=TypedVariantMap()
Unknown Variant Key(4095584000)=TypedVariantMap()
```

未知键无法由单端日志可靠反解原始字符串。

## 模组审计

本局加载了 Quick Deals 2460661464、海克斯大乱斗 3751996207、海克斯扩展 3765281534、Annex City-States Remastered 3323036834 等。Quick Deals缓存脚本保存字符串报价；Annex脚本在 `Script/ACS_Remastered_Script.lua` 的 192、211、236 行把 `ANNEXED_STATES` Lua table 写入 Player Property，产生 `TypedVariantMap`，是高风险候选。其它已加载外部脚本也存在 table 型 Property 写入，但当前日志不足以将未知哈希唯一映射到某个模组。

红祭司普通模式脚本当前未发现向 Player Property 写入 Lua table；本次首个差异中 `LOTM_*` 值基本一致。单端日志仍不能证明远端使用了相同 Workshop 文件／版本。

## 边界

`Lua.log` 后段的 duplicate path holders 与大厅 MVC `StringParameterInstance` 警告均晚于首次 OOS 或属于 UI 层，不能作为本局首因。需要对方 Modding.log、双端资源哈希及逐项 A/B 复现才能定案。未据此修改玩法或外部模组。
