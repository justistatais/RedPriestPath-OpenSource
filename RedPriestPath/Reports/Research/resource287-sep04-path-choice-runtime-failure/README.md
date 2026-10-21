# 资源287｜2026-09-04 实机无法选择途径诊断

## 结论

最新救援联机局无法选择途径的直接原因，是红祭司主Gameplay在载入阶段提前终止。`LOTM_RP_Gameplay.lua`先尝试把救援Phase1／2／3注册到同一个网络同步调度器；三个`include()`没有产生任何注册项，随后第364行的完整性保护抛出：

`[LOTM_RESCUE] FATAL ordered network bootstrap registration incomplete`

主文件因此没有继续执行第372行的`include("LOTM_RP_Lifecycle")`。途径选择Gameplay监听`GameEvents.LOTM_RP_Command_SelectPath.Add(OnSelectPath)`位于Lifecycle第1438行，最终根本没有注册。UI仍能正常载入并显示按钮，但提交后没有Gameplay处理者，所以表现为“选择不了途径”。

## 最新现场证据

- 日志时间：2026-09-04 10:37。
- `Lua.log:109`：`MPTurnSync initialized version=6 network=true rescueMode=true source=ENTRYPOINT`，说明实际运行的是资源287入口，且救援模式判定正确。
- `Lua.log:110`：主Gameplay在`LOTM_RP_Gameplay.lua:364`唯一一次Runtime Error后停止载入。
- `Lua.log:117-120`：Phase1／2／3随后只以独立被动网络上下文载入，不能替代主上下文注册。
- `Lua.log:161`及`UserInterface.log:844-848`：途径选择UI正常载入；日志中没有Lifecycle初始化或途径命令监听注册记录。
- `Modding.log:2343-2346,3982-3989`：主Gameplay与三个独立Phase AddGameplayScripts均已注册；但运行时组件清单和应用阶段都没有出现声明的`LOTM_RP_GAMEPLAY_DEPENDENCY_FILES`、`LOTM_RESCUE_BOOTSTRAP_GAMEPLAY_DEPENDENCY_FILES`、`LOTM_RP_GAMEPLAY_SHARED_FILES`三个Gameplay依赖ImportFiles动作。主入口的Phase脚本因此没有获得可用的同上下文include／注册链。
- 当前源码与本机安装中的主Gameplay、Lifecycle、Phase1／2／3及`.modinfo` SHA-256全部一致；不是装错版本或漏覆盖安装目录。

## 边界

- 这是资源287自身的Gameplay接线／VFS动作缺陷，不需要修改Quick Deals或任何其他模组。
- 资源287的完整性保护正确揭示了Phase注册失败，但放在Lifecycle之前，使一个救援启动故障扩大成全部主Gameplay（包括途径选择）停止。
- 本轮按用户“检查为什么”的请求只完成诊断和证据固化，未修改玩法代码、版本、发布包或本机安装。
- 下一修复不能只删除FATAL或把Lifecycle挪到前面；必须同时消除Phase1／2／3对当前未实际生效ImportFiles接线的依赖，并保证救援有序注册与普通模式隔离，再制作新资源包实测。
