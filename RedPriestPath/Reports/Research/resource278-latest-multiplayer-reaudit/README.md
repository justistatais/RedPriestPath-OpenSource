# 资源278｜最新问题与联机代码再审计

## 最新实机结论

- 会话时间：2026-08-29 20:23～21:02；首次同步检查在20:23:21，下一秒即OOS。
- `Modding.log:66`明确报资源277的`Scripts/LOTM_QD_MultiplayerCompat.lua`未加入`<Files>`。组件动作被列出但脚本没有注册，故资源277的Quick Deals修复从未运行。
- 首次可识别Player Property差异仍只有两名人类各自的`QD_SELLABLE_DEALS`／`QD_BUYABLE_DEALS`；与上述发布遗漏完全吻合。
- 同次快照另有两个DynamicModifier档案的Owner／Subjects互换：一端先创建Player 3 Modifier，另一端先创建Player 4首城District Modifier。随后重载后该差异消失。结合本地Phase7日志仅Player 3在启动期附加一个阶段Modifier，最强代码内候选是Phase7在脚本载入时与引擎区域Modifier并发创建。
- `Lua.log`有526次本MOD同一错误：`LOTM_BE_BlackEmperor.lua:742 function expected instead of nil`。Gameplay环境不能用城市UI侧的`city:GetTrade():GetOutgoingRoutes()`枚举方式。

## 外部代码行为参考

仅研究公开／本机订阅代码的行为与接口，不复制无明确许可证实现。

1. Quick Deals `2460661464/gameplay/qd_cachemanager.lua`：反例。按`Game.GetLocalPlayer()`选择玩家，并由UI调用Gameplay闭包写同步Player Property；客户端本地缓存因此进入GameCore同步状态。
2. More Historical Leaders `3754917538/Lua/MaoZedong_Gameplay.lua`：其贸易路线计数使用带空值检查的`player:GetTrade():CountOutgoingRoutes()`，证明这是Gameplay侧可用接口。本MOD只采用该API事实与防御式检查，不复制业务实现。
3. 海克斯大乱斗 `3751996207`：UI选择通过`EXECUTE_SCRIPT`提交，Gameplay端验证后才写Property／附加Modifier；UI本地随机不调用`Game.GetRandNum`，以免扰动同步随机流。该权威边界与本项目既定架构一致。
4. Firaxis／和而不同Gameplay脚本：`GetOutgoingRoutes()`出现于UI TradeSupport；Gameplay脚本主要以`TradeRouteActivityChanged`事件参数结算，进一步支持不在Gameplay枚举城市UI路线表。

## 资源278修复

- 将Quick Deals兼容脚本加入`.modinfo <Files>`；新增通用门禁，任何FrontEnd／InGame Action引用文件未纳包均阻止构建。
- 黑皇帝路线计数改为`PlayerTrade.CountOutgoingRoutes()`，API缺失时不写基线、不计算delta并记录拒绝原因。
- Phase7 v4移除载入期`ReconcileAll()`，改为最低存活主要文明的同步`GameEvents.PlayerTurnStarted`锚点；旧档已附加效果不受影响，待迁移效果最迟下个世界回合兑现。
- 偷盗者Boost选择改为共同游戏／地图种子、玩家ID、世界回合和通道的稳定哈希，不再调用`Game.GetRandNum`。
- 新增`validate_multiplayer_determinism.py`：禁止Gameplay读取LocalPlayer、禁止UI直接写Property／Modifier／金币／产出、锁定Quick Deals纳包、工坊／偷盗者不推进同步RNG、贸易计数API和Phase7同步锚点。

## 全工程再审计结果

- Gameplay脚本中`Game.GetLocalPlayer()`：0。
- UI直接`SetProperty`／`AttachModifierByID`／`ChangeGoldBalance`／`GrantYield`：0；UI变更均经`EXECUTE_SCRIPT`或PlayerOperation提交。
- 工坊事件与偷盗者回合处理中的`Game.GetRandNum`：0。
- 剩余同步RNG调用位于Gameplay权威的同步事件／世界回合锚点；候选表已使用稳定排序。本轮未观察这些位置成为首次分叉。
- 仍有其他系统在脚本初始化中做带Property幂等保护的旧档迁移与Modifier恢复；此次只有Phase7有动态Modifier序号交换的实机对应证据，因此不做无证据的大范围时序改写。

## 证据块账本

- `net_message_debug.log` 13,612,115字节：检查首次同步块258～568行、后续同步索引及DynamicModifier 2668～2670；未整份加载。
- `Lua.log` 5,281,900字节：按本MODRuntime Error聚合，526次均为黑皇帝742行；抽取858～893行调用栈。
- `Modding.log` 990,466字节：按RedPriest／Quick Deals／兼容组件筛选，确认Invalid file reference与组件加载顺序。
- 外部参考仅读取命中函数附近与搜索索引；未递归读取历史封存目录，未修改外部Workshop文件。

## 待实测边界

- 静态与构建通过不等于多人通过。双客户端须确认日志出现`[LOTM][QDCompat] multiplayer local cache enabled`，且Modding.log不再有Invalid file reference。
- 连续至少4个世界回合不得出现`QD_*`差异、DynamicModifier Owner互换、黑皇帝742错误或自动Game State重载；同时测试Quick Deals打开／成交和一次保存重连。
