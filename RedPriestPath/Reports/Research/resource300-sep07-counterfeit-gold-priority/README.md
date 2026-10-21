# 资源300｜假金币透明顶栏与交易优先扣款

> 语义更正（资源301）：上一版报告把截图查看器显示的黑色透明区域误读为应删除的 Civ VI 资源栏背景。实际需求是恢复原生 `TopBar_YieldBacking.dds`／`YieldBacking`，同时保持金币图片自身透明；资源301已完成该修正。

更新：2026-09-07

## 输入与边界

- 输入：“排查原因7”最新记录及用户提供的两张实机截图。
- 范围：普通单机偷盗者顶栏与一次性金币外交。资源291联机实现继续封存；不修改 Quick Deals 外部模组文件或其他模组。
- 证据边界：本报告只记录源码、美术、静态门禁与构建结果；不把它们写成游戏内成功。

## 定因

1. `ArtSources/LOTM_TP_FakeGoldTransparent.png` 与 `Art/LOTM_TP_FakeGoldIcon22.dds` 均为 RGBA，alpha 范围为 0—255。棕色背景不在金币建模中，来自 `LOTM_RP_HUD.xml` 的背板贴图与 `YieldBacking` 样式。
2. 截图中的 `ICON_RESOURCE_LOTM_TP_FAKE_GOLD_TRADE` 占位来自资源297—299用于独立假金币交易栏的隐藏战略资源。旧 HUD 只检查 `ResourceInstance` 根容器文本，而真正图标字符串在嵌套 `ResourceText` 标签，因此隐藏会漏掉。
3. 用户要求交易仍显示原生金币，但成交后先消耗假金币，所以独立假金币交易栏与“假金币转为 AI 真金币”的设计均应废弃。

## 实现

- 删除顶栏假金币容器的背板贴图与样式，仅保留经 `IconManager` 绑定的透明 DDS 金币。
- HUD 递归检查原生 `ResourceStack` 子控件，隐藏真正持有假金币图标文本的整个资源实例。
- 标准外交使用 Firaxis `DiplomacyDealView_` 通配扩展，Quick Deals 仅监听其公开的 `QD_StartAIOfferAccept` / `QD_EndAIOfferAccept` 事件。两者均不改写金币显示、AI 估值或外部 Quick Deals 文件。
- 成交后 Gameplay 校验付款双方的原生金币 delta，再以 `min(假金币库存, 一次性金币付款)` 替换：扣除玩家假金币，退回同额玩家真金币，并从 AI 移除同额真金币。任一步失败都按实际观察 delta 回滚；序列号防止重复结算。
- 旧隐藏载体保留数据库定义以兼容旧档，但不再镜像或交易；Gameplay 以迁移版本 1 对每个存活主要玩家只清理一次。

## 结算不变量

| 议价付款 | 玩家假金币 | 假金币消耗 | 玩家真金币净消耗 | AI 真金币净获得 |
|---:|---:|---:|---:|---:|
| 10 | 20 | 10 | 0 | 0 |
| 10 | 6 | 6 | 4 | 4 |
| 10 | 0 | 0 | 10 | 10 |

AI 从不获得 `RESOURCE_LOTM_TP_FAKE_GOLD`，因此无法将假金币兑换成真金币。

## 待实机验收

- 顶栏只有透明金币建模，无棕色底板、无重复资源项、无图标占位或加载标。
- 标准外交和 Quick Deals 分别完成全假金币、部分假金币和零假金币三类一次性付款，对照上表核对双方库存。
- 拒绝、取消与未成交报价不扣款；读档不重复结算。
- `Lua.log` 无新的 HUD / Diplomacy / Quick Deals Runtime Error，并出现符合预期的 `fake gold deal settled` 记录。

持续回合金不在本次库存替换范围内；它是长期合同债务，不是一次性金币付款。
