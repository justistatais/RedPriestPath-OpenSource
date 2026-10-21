# 红祭司途径 × 和而不同 v2.2 兼容性诊断

日期：2026-08-28  
性质：只读代码审计；未修改、构建、安装或启用任何模组。

## 结论

已确认的主因不是数据库主键重名，而是双方同时使用 Civ VI 的 `ReplaceUIScript` 整段替换同一原生 UI 上下文。重叠上下文共有三个：`CityPanel`、`CityStates`、`UnitFlagManager`。这种替换不能自动合并；最终只会运行其中一套入口脚本，另一方在该上下文中的补丁丢失。加载顺序还会造成双向覆盖，因此不能通过简单调整订阅顺序获得完整兼容。

## 审计对象

- 红祭司源码：`RedPriestPath.modinfo`，当前本地候选 `0.1.0-rc.243 / 资源275 / 状态35`。
- 本机订阅的和而不同：`D:\app\steam\steamapps\workshop\content\289070\2465378070`；`DL.modinfo` 标记 Mod ID `521b8777-0977-4859-a5ee-3e411a732e5c`、版本 `2.2`，共 959 个文件、约 506 MB。
- 公开参考：Steam Workshop 条目 `2465378070`、Gitee `carbongo/civ6-harmony-in-diversity` 与官方 Wiki。公开仓库版本早于本机 v2.2，因此最终结论以本机订阅源码为准。

## 确定冲突

| LuaContext | 红祭司替换 | 加载序 | 和而不同替换 | 加载序 | 直接结果 |
|---|---|---:|---|---:|---|
| `CityPanel` | `UI/LOTM_AI_Cult_CityPanel.lua` | 279 | `UI/Replacement/DL_CityPanel.lua` | 150000 | 和而不同后加载；红祭司追加的邪教文化产出来源提示不会进入最终 CityPanel。 |
| `UnitFlagManager` | `UI/LOTM_PP_UnitFlagManager.lua` | 279 | `UI/Replacement/UnitFlagManager_UpdateReligionIcon.lua` | 150000 | 和而不同后加载；红祭司途径持有者、怪物、傀儡和救赎单位的旗帜颜色／徽记补丁丢失。 |
| `CityStates` | `UI/LOTM_WORLD_CityStates.lua` 或 Better City States 包装 | 99988/99989 | `UI/Replacement/citystates.lua`、`citystates_bst_xp2.lua` | 5000/5002 | 红祭司后加载；和而不同的城邦 Lua 被覆盖，而它导入的定制 XML 仍可能保留，形成“和而不同 XML + Firaxis/红祭司 Lua”的非配套组合。三教会虚拟城邦功能与和而不同城邦功能不能同时完整保留。 |

### CityStates 的额外识别缺口

红祭司只用独立 Better City States 的 Mod ID `13E8BCDF-98EC-4C03-3641-72D519B0047C` 选择包装。和而不同把 Better City States 派生代码直接集成在自己的 Mod ID 下，因此红祭司不会识别它，会走 `NO_BETTER_CITY_STATES` 分支并 `include("CityStates_Expansion2")`。这进一步确认当前没有针对和而不同的组合入口。

## 未发现的冲突

- 在和而不同的 Lua/SQL/XML/modinfo 中未找到 `LOTM_` 命名空间或红祭司 Mod ID；在红祭司中也未找到和而不同 Mod ID或兼容 Criteria。
- 红祭司新增数据库对象普遍使用 `LOTM_` 前缀，本轮没有发现双方直接插入同名 Type、Modifier 或 Requirement 的证据。
- 两者都会改写大量基础游戏数据，仍可能存在数值语义覆盖，但它不是当前最先、最确定的兼容断点。

## 日志边界

本机现有 `Database.log`、`Modding.log`、`Lua.log` 最后更新时间为 2026-08-24。该会话加载了红祭司，但没有加载和而不同，不能作为双模组实机复现证据。`Database.log` 中的重复本地化错误指向官方 `CurrentClickouts` 文件，与这次三处 UI 冲突无关。

## 版本与联机边界

- 本机资源275新增的偷盗者 `UnitPanel` 操作按钮尚未上传，不能解释公开版资源273用户的既有反馈；上述三处替换在既有公开版本中已经存在，足以解释反馈。
- 和而不同 v2.2 的 modinfo 明确写有 `SupportsMultiplayer=0`、`SupportsHotSeat=0`。若反馈发生在多人游戏，除上述 UI 冲突外，和而不同本身也没有声明支持该模式。

## 建议修复方向（尚未实施）

1. 新增专门以和而不同 Mod ID 为 Criteria 的兼容组件，不改它的 Workshop 文件。
2. 为三个重叠上下文制作组合入口，以和而不同 v2.2 文件为基底，只注入红祭司最小补丁：CityPanel 邪教来源、UnitFlag 标记、CityStates 三教会。
3. 对 CityStates 同时匹配和而不同的 XML 与 Lua，而不是继续 include Firaxis 或独立 Better City States 版本。
4. 使用独立兼容测试矩阵验证普通／救赎、三教会使者、邪教提示、所有自定义单位旗帜；若要多人测试，必须把“和而不同官方未声明支持多人”作为单独边界。
5. 兼容层必须按对方版本门控；和而不同更新 UI 文件后先做差异审计，不能永久复制一份不跟踪上游的 117 KB CityStates 脚本。

