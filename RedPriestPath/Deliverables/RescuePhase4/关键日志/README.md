# 关键日志待采集

真实游戏测试时保存包含以下内容的`Lua.log`：

- `phase4 READY version=1`
- 三档`sequence strength ... B=... level=... bonus=... target=...`
- 守卫生成、位置纠正、击杀与清营回调归因
- 保存读取前后同一工坊PlotIndex、守卫UnitID／出生B

本目录当前没有伪造游戏日志；自动验证输出记录在本阶段验证报告。

