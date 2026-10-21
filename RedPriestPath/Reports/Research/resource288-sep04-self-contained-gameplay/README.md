# 资源288｜自包含Gameplay启动链修复

## 修复目标

资源287最新实机中，主Gameplay虽正确识别救援模式，却无法在同一上下文include Phase1／2／3；注册完整性门禁随后在Lifecycle之前FATAL，导致途径UI可见但`LOTM_RP_Command_SelectPath`没有Gameplay监听者。运行时`Modding.log`同时证明四个声明的Gameplay依赖ImportFiles动作均没有进入组件清单。

## 同类问题审计

- 主入口不仅有Phase1／2／3三个include，后面Lifecycle、晋升、完美者、黑皇帝、偷盗者、工坊、世界事件、教会和救援Phase5～10等约30个模块也依赖同一类跨Action VFS接线。只补三个Phase会把故障推迟到下一个include，不能形成完整修复。
- `.modinfo`原有主Gameplay、三个独立救援Gameplay和四个Gameplay ImportFiles动作；资源287实机只选择了前四个AddGameplayScripts，四个ImportFiles全部缺席。独立救援上下文在网络模式又按设计保持被动，无法接管。
- 当前所有InGame `AddGameplayScripts`已收敛为两个：红祭司自包含主bundle，以及有Quick Deals时才启用的独立兼容层。两个实际运行文件均不再包含本模组本地include。
- UI侧只发现`LOTM_AI_Cult_Diplomacy_Extension.lua`和`LOTM_WORLD_CityStates.lua`两个本模组include目标；二者均在资源287实机已确认应用的`LOTM_RP_UI_FILES`动作内。独立门禁现会持续检查这一关系。

## 实现

- 新增`Tests/generate_gameplay_bundle.py`，从`LOTM_RP_Gameplay.lua`递归收集36份本模组Gameplay源码，确定性生成`Scripts/LOTM_RP_Gameplay_Bundle.lua`。
- bundle先定义所有模块加载器，再运行主入口；每个模块在独立函数作用域内执行，保留原include的局部变量隔离。循环依赖、缺失模块或模块异常都会带模块名明确失败。
- 所有本模组Gameplay include在生成文件中替换为内嵌加载器调用；生成文件末尾按模式验证30个公共模块加3个救援模块，或30个公共模块加偷盗者模块，并输出`[LOTM][Bundle] verified version=1 ...`实机哨兵。
- Phase1／2／3不再保留独立Gameplay上下文；救援单机和联机均由同一bundle主上下文执行。原Phase1→Phase2A、Phase2→Phase3同步注册顺序检查仍只在网络游戏执行。
- 移除`LOTM_RP_GAMEPLAY_DEPENDENCY_FILES`、`LOTM_RESCUE_BOOTSTRAP_GAMEPLAY_DEPENDENCY_FILES`、`LOTM_TP_GAMEPLAY_DEPENDENCY_FILES`、`LOTM_RP_GAMEPLAY_SHARED_FILES`四个已被实机证伪的依赖动作。

## 门禁与边界

- `validate_gameplay_bundle.py`检查bundle陈旧、运行Action唯一性、无残留本地Gameplay include、无旧ImportFiles／独立Phase动作、关键模块嵌入、模式分支和UI本地include覆盖。
- 全量静态门禁、联机确定性、普通偷盗者、UI、资源249保护、AI邪教、随机事件、魔物以及救援Phase1～10专项均通过；生成bundle经去除Firaxis类型标注后由Lua解析器完整解析。
- 本次不改玩法数值、不升任何存档Property状态版本、不修改Quick Deals或其他模组。资源287正常档设计兼容资源288；资源286／287已经缺失救援开局状态的坏档仍只能尽力补建，不能代替全新局验收。
- 构建、文件哈希和静态门禁不等于文明VI实机或双客户端联机通过。新局必须在`Lua.log`看到bundle逐模块载入及最终verified哨兵，并验证途径选择、中央76格、四城、永久联盟和首次同步。

## 发布闭环

- 版本为`0.1.0-rc.256／资源288`，最终发布物共697个文件；最终ZIP哈希记录在工作区根`STATUS.md`及同名`.zip.sha256`。
- 覆盖前确认文明VI未运行，并将本机资源287完整备份为`backups/RedPriestPath-installed-resource287-before-resource288-20260904.zip`，SHA-256 `7647F9E6D5D0EB0D5FEE2037376764862234CFC98E954839A2382B53F7000D90`。
- 安装只覆盖`Mods/RedPriestPath`。候选阶段的源码、ZIP、Manifest和本机安装目录均为697文件，缺失、额外与哈希差异均为0；纳入本记录后执行最终重建并再次覆盖／校验。
