# 资源279｜2026-08-30多人读档异常退出诊断

## 结论

当前最强证据指向红祭司资源279的Quick Deals旧缓存清理执行得过早：兼容脚本在Gameplay脚本载入、GameCore仍处于存档反序列化阶段时调用`Player:SetProperty(..., nil)`。Lua日志打印“本地缓存已安装”后恰好在进入清理函数前中断，后续“清理完成”“Ability索引指纹”“守卫已加载”三类日志均未出现；进程随后异常结束，但Windows没有生成新的WER崩溃报告或转储。

`和而不同 v2.2`同时存在一个明确但非终点的大厅Lua错误：`StagingRoom.lua:1830`在`PlayerLeader`参数缺失时直接访问`parameter.Value.Value`。该错误发生后游戏仍继续完成模组就绪、接收快照、配置内容并初始化红祭司Gameplay，所以它会破坏大厅稳定性，但不是本次日志中最后执行到的崩溃边界。

## 检查范围

先检查文件大小和时间，再按固定范围读取：

- `Lua.log`：40,247字节／298行；检查1～40、260～298及错误命中。
- `Modding.log`：295,765字节／4,067行；只检查组件注册、资源279和失败命中。
- `net_message_debug.log`：68,967字节／40行；全文事件量很小，检查快照序列。
- `LoadGameViewState.log`：558字节／10行；全文。
- `GameCore.log`：2,507字节／23行；全文。
- `Renderer.log`：27,745字节／549行；检查末40行及设备错误命中。
- Windows WER：最近CivilizationVI记录仍为2026-08-22的旧AppHang；2026-08-30没有新报告。文明VI Dumps和用户CrashDumps目录没有本次转储。

原始日志保留在游戏日志目录，没有复制进源码或GitHub仓库。

## 时间线

1. 00:07:48～00:08:40：进入多人房间并完成双方MOD ready。
2. 大厅期间`和而不同`的`UI/Replacement/StagingRoom.lua:1830`出现一次空值错误；调用栈为`UpdatePlayerEntry → PlayerInfoChanged_SpecificPlayer → OnPlayerInfoChanged`。
3. 00:08:50～00:08:52：收到第一份2,745,137字节网络快照，开始`LoadGameViewState`。
4. 00:08:59：配置内容完成；开始`GAMECORE_UNSERIALIZE_GAMESTATE`。
5. 红祭司普通Gameplay、救援脚本、工坊和三教会正常初始化。资源279兼容脚本最后一条为：`multiplayer local cache installed reason=SCRIPT_LOAD`。
6. 该日志语句之后，代码下一步就是遍历PlayerID并读取／清除`QD_SELLABLE_DEALS`和`QD_BUYABLE_DEALS`。预期的后续日志全部缺失。
7. 00:09:18第一份快照处理完成；00:09:26第二份2,744,687字节快照因仍处于`LoadInProgress`被忽略。00:09:37 UI Load结束，之后进程日志中断。

## 归因强度

- **高置信风险点**：资源279在脚本加载期修改同步Player Property。它与日志最后边界逐语句吻合，并且是资源278→279唯一直接影响本次加载阶段的新行为。
- **确定的并发问题**：`和而不同 v2.2`大厅Lua未检查`parameters.Parameters["PlayerLeader"]`是否存在；其`.modinfo`还明确声明`SupportsMultiplayer=0`。
- **不能声称**：无原生转储或异常码，无法证明具体C++崩溃地址，也不能仅凭日志断言`SetProperty(nil)`是唯一可能原因。

## 后续修复边界

- 禁止在Gameplay脚本载入期写任何同步Property。
- Quick Deals旧缓存迁移必须等待确定性的同步Gameplay事件；若第一次GameSyncCheck早于安全事件，则不能以不安全启动写入换取“首次检查前清理”，应改用不修改同步状态的兼容策略或明确要求新存档／一次受控迁移。
- `和而不同`兼容研发仍按用户此前决定暂缓；多人测试时应注意其官方元数据声明不支持多人。
- 本报告是诊断，不包含资源280修复；当前源码仍为rc.247／资源279，以便保留事故现场供Git历史追溯。
