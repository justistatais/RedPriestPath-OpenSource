# 资源283最新局无法选择非凡途径

## 结论

这是红祭司自身的Gameplay加载失败。最新`Lua.log`中`LOTM_MP_TurnSync`初始化日志为0，随后有24个红祭司Runtime Error和24个include加载失败。生命周期在`LOTM_RP_Lifecycle.lua:1427`调用`LOTM_MP_TurnSync.Add`时立即终止，因此位于后面的`GameEvents.LOTM_RP_Command_SelectPath.Add(OnSelectPath)`从未执行；UI按钮存在，但同步选择命令没有接收者。

## 证据

- 日志时间：2026-08-31 12:42；实际脚本路径为本机安装目录`.../Mods/RedPriestPath`。
- 第一条核心错误：`LOTM_RP_Lifecycle.lua:1427: attempt to index a nil value`。
- 同型错误继续覆盖进度、完美者、黑皇帝、偷盗者、世界状态、魔物、事件、封印物、工坊、教会等，共24处。
- `Lua.log`没有任何`[LOTM][MPTurnSync] initialized version=2`、handler或startup记录，也没有任何成功的途径选择结算记录。
- `LOTM_RP_PathChoice` UI正常加载；问题不在按钮布局或本地UI。
- 安装文件存在且与源码SHA-256一致，`.modinfo`也把它列入根Files及ImportFiles。因此不是资源281的“文件完全漏列”原样复发，而是当前include/VFS装载方式仍未保证它在主Gameplay入口前执行。
- `Modding.log`显示`LOTM_RP_GAMEPLAY_ADDIN`先于`LOTM_RP_UI_FILES`应用；二者LoadOrder同为204。这个同序依赖让主入口对ImportFiles提供的共享适配脚本没有可靠先后保证，是当前最高置信的加载层原因。

## 修复方向（尚未实施）

下一版不能继续只靠“文件已纳包／已列ImportFiles”的静态门禁。应让同步适配器在主Gameplay入口内确定执行，或给提供include依赖的ImportFiles更早的明确LoadOrder，并在入口处对`LOTM_MP_TurnSync.VERSION`做强制哨兵检查；若缺失应只报一个明确致命错误并停止，而不是让24个模块依次崩溃。还需增加模拟实际Action先后或实机初始化日志门禁。

本报告只诊断；未修改Gameplay、版本或本机安装。
