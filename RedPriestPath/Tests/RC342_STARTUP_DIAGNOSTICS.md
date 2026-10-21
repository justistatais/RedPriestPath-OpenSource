# rc.342 启动临时诊断

本轮诊断针对“自己创建多人房间并启动”的崩溃。资源 374 增加启动检查点，供下一次实际运行定位；它不是已经证实稳定的修复版。rc.241 的用户历史反馈与当前版本的静态比较，也不能单独证明某一处差异就是崩溃原因。

启动后查看游戏日志目录中的 `Lua.log`：

`C:\Users\20594\AppData\Local\Firaxis Games\Sid Meier's Civilization VI\Logs`

诊断行示例：

```text
[LOTM_DIAG] r=374 seq=42 ctx=CityBootstrap point=GetRequestingPlayer.IsTurnActive.BEFORE args=0
[LOTM_DIAG] r=374 seq=43 ctx=CityBootstrap point=GetRequestingPlayer.IsTurnActive.RETURN args=false
[LOTM_DIAG] r=374 seq=44 ctx=CityBootstrap point=GetRequestingPlayer.RETURN.inactive args=0
```

这个例子说明读取已返回、玩家尚未处于活动回合，因此 UI 暂不提交命令；不能把它解释成读取时崩溃。

- `r=374` 是本轮诊断资源号。`bootstrap policy=COMMAND_ONLY resource=373` 仍是沿用的城市启动策略说明，不表示运行的是旧诊断版。
- `seq` 是同一原生 Lua 上下文内共享的计数；`ctx` 标识模块或调用位置。不同原生 Lua 上下文可能各自从 1 开始，序号不能跨上下文比较，也不是游戏事件的全局同步序号。
- `MODULE BEGIN/RETURN`、`CONTEXT BEGIN/END` 表示模块或脚本执行范围；`EVENT BEGIN/END` 表示一次监听回调的范围。嵌套加载或回调可在两者之间插入其他行。
- `BEFORE/AFTER` 围住一条原有语句；若该语句包含多个原生调用，只能先缩小到整条语句。手写的 `...IsTurnActive.BEFORE/RETURN` 等检查点进一步区分具体 API 调用与标量结果。
- `RETURN BEFORE` 只说明即将计算返回表达式，**不表示函数已经成功返回**。`if`、循环等语句内部可能提前 `return`；缺少相应 `AFTER` 不能单独证明崩溃。还要检查外层事件结束、明确的返回原因及后续日志。
- `args` 只输出标量，长字符串会截短；对象显示类型占位符，不调用对象的 `tostring`。日志不为取诊断信息额外读取游戏对象，也不写 Gameplay Property。

每次崩溃后应先保存该次 `Lua.log`、`Modding.log`、`Database.log`、`net_message_debug.log` 和可用 dump，再启动下一局。游戏会覆盖日志；dump 也可能残留于更早的失败尝试。核对文件修改时间、日志中的本次启动时间和加载版本，确认属于同一次运行后再关联分析。仅因 dump 文件存在，不能把它当成本次崩溃证据。

定位时从最后完成的检查点向后找未完成范围，同时考虑正常提前返回、Lua 错误和日志缓冲。最后一行日志只能提供边界；原生崩溃可能发生在游戏随后处理事件时，也可能未及时刷出最后几行。测试中的“模拟原生调用抛错”验证检查点覆盖，不等于模拟或解决了真正的原生访问冲突。

本版开启密集的临时日志，地图搜索和 UI 刷新可能产生较大日志并增加开销；本轮用于定位启动边界，不能用于性能对比。

需要关闭诊断时，将 `Scripts/LOTM_StartupTrace.lua` 中的 `Enabled` 改为 `false`，重新生成运行脚本、构建并安装，使所有嵌入副本一致。直接修改某一个生成文件不能可靠关闭整轮诊断。
