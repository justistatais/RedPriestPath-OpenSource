# 阶段3关键日志

真实测试后请保存`Lua.log`、`Database.log`和`Modding.log`到本目录。重点搜索：

- `[LOTM_RESCUE][Phase3] loaded`
- `[LOTM_RESCUE][Phase3] READY`
- `[LOTM_RESCUE][Phase3] check`
- `[LOTM_RESCUE][Phase3] spawned`
- `reason=TARGET_DEFICIT`
- `reason=DEATH_REPLACEMENT`
- `[LOTM_RESCUE][Phase3] removed`
- `NO_LEGAL_EMPTY_PLOT`
- `RUNTIME_FAILURE`、`guarded failure`、`ERROR`

双客户端验收时应比较相同世界回合的church、tier、serial、unit、plot、live、cap字段。
