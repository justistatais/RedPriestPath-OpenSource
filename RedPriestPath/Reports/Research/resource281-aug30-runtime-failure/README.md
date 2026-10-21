# 资源281最新联机会话：适配层未导入与旧QD属性OOS

## 日志范围

- 会话时间：2026-08-30 19:54～20:02。
- `Lua.log`：92,301字节／1,036行，检查620～875及所有红祭司Runtime Error。
- `net_message_debug.log`：3,307,347字节／3,988行，检查4次同步检查及首次差异区间175～205。
- `Modding.log`：573,208字节／7,965行，检查红祭司Action注册与实际路径。

## 结论一：资源281联机适配层没有进入Gameplay VFS

`LOTM_RP_Gameplay.lua`第5行执行`include("LOTM_MP_TurnSync")`，但日志没有任何`[LOTM][MPTurnSync] initialized`或handler注册记录。随后生命周期、进度、完美、黑皇帝、偷盗者、AI教派、魔物、世界事件、封印物、工坊、教会和多项救援脚本在调用`LOTM_MP_TurnSync.Add`时连续报`attempt to index a nil value`：

- 红祭司nil Runtime Error：40次。
- 红祭司`Error loading file`：40次。

源码与安装中确实存在`Scripts/LOTM_MP_TurnSync.lua`，根`<Files>`也列出了它；但实际供include解析的`LOTM_RP_UI_FILES` ImportFiles动作列出了其它被include脚本，却遗漏该新文件。因此物理纳包和Manifest校验通过，Gameplay虚拟文件系统仍无法解析它。资源281没有实际执行设计中的多人同步回合迁移，大量核心模块反而未加载。

现有发布门禁只验证Action引用文件属于根`<Files>`，没有枚举`include(...)`目标并验证其进入对应ImportFiles/VFS，所以静态检查产生了假通过。

## 结论二：首次OOS仍是旧档QD缓存属性

本会话不是新局初始化：第一次检查发生在Game Turn 30结束。19:57:59启动同步检查，19:58:02首个差异为Player 0的`m_kProperties`：

- 本地`QD_SELLABLE_DEALS=TypedVariantMap()`、`QD_BUYABLE_DEALS=TypedVariantMap()`。
- 远端两项均为非空嵌套`TypedVariantMap`报价缓存。

随后才扩散到单位Ability、AI建造评估等。4次同步检查共1508项AutoArchive mismatch。

资源280/281兼容层成功记录`multiplayer local cache installed`，但其设计只把未来Quick Deals缓存留在本地Lua内存，并明确保留旧档中已有`QD_*`Property，以避开资源279在反序列化期删除属性导致的退出。因此它能避免新增QD同步写入，却不能修复一个已经保存了双方不同QD表的旧档。这是当前实现的已知未解决边界，不是Quick Deals本身突然变化。

## 修复边界

本轮只诊断，未改源码、版本、发布包或安装目录。下一版本需要同时：

1. 把`LOTM_MP_TurnSync.lua`加入实际ImportFiles/VFS，并新增include目标可解析门禁和初始化哨兵。
2. 为旧档QD差异设计载入完成后的同步迁移，不能回到资源279的脚本加载／反序列化期直接删除做法；必须先以安全同步事件实测清理时机。
3. 资源281不应继续用于多人验证，因为核心脚本未加载；本次日志不能验证`PlayerTurnStarted`方案是否有效。

