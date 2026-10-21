# 资源289｜文明VI模组元数据缓存失效修复

## 现象

- 用户安装资源288后，救援联机局在进入地图时退出。
- 2026-09-04 11:32的`Lua.log`显示主Gameplay入口只完成TurnSync v6初始化，随后在`Scripts/LOTM_RP_Gameplay.lua:366`报`FATAL ordered network bootstrap registration incomplete`。
- 同期`Modding.log`把`LOTM_RP_GAMEPLAY_ADDIN`注册为旧的`Scripts/LOTM_RP_Gameplay.lua`，并继续注册Phase1、Phase2A、Phase3三个独立Gameplay Action；这与安装目录资源288的`.modinfo`（唯一主入口应为`LOTM_RP_Gameplay_Bundle.lua`）矛盾。

## 根因证据

- 源码与安装目录的`.modinfo`逐文件SHA-256一致，内容均为资源288，主Action均指向自包含bundle。
- 只读查询`C:\Users\20594\AppData\Local\Firaxis Games\Sid Meier's Civilization VI\Mods.sqlite`：同一Mod ID的缓存版本仍为`281`，缓存扫描时间为FileTime `134294688000000000`，即2026-07-26 00:00。
- 资源281以来的发布器给每个ZIP条目固定写入同一时间戳`(2026, 7, 26, 0, 0, 0)`。覆盖解压后`.modinfo`时间没有变化，文明VI没有重解析新版本，而是继续使用资源281的组件表并读取已被覆盖的新Lua源码。
- 因此本次失败是“资源288脚本 + 资源281 Action表”的混装。此前基于该运行日志断言资源287自身的ImportFiles Action被遗漏并不成立；资源287的`.modinfo`当时根本没有进入`Mods.sqlite`。

## 修复

- 资源289保留资源288的单一自包含Gameplay bundle，不回退Gameplay逻辑或资源287的功能修复。
- 发布器继续确定性构建，但统一ZIP时间改为`2026-07-26 00:00 + .modinfo资源号分钟数`。资源289对应2026-07-26 04:49；后续每个资源号都会得到不同且递增的时间戳。
- 本机安装资源289时只覆盖`Mods/RedPriestPath`，并回读安装后的`.modinfo`时间戳、文件集合和SHA-256；不删除`Mods.sqlite`，让游戏在下次启动时按文件时间变化自行刷新。
- 覆盖前已将当前资源288安装目录备份为`D:\codex_tasks\文明6\backups\RedPriestPath-installed-resource288-before-resource289-20260904.zip`，SHA-256为`E2A9B30CF4A0D6FF619624B71B7E8C0F202988E415848E40B1BE1BE50F7331D7`。候选安装回读698个文件，`.modinfo`时间为2026-07-26 04:49:00。

## 验证边界

- 静态、Lua解析、构建、ZIP时间戳及源码／安装哈希闭环只能证明发布与安装一致。
- 资源289下次启动后，应以新`Modding.log`确认`LOTM_RP_GAMEPLAY_ADDIN`注册`Scripts/LOTM_RP_Gameplay_Bundle.lua`，且不再出现三个独立Phase Action；随后再由双客户端新救援局验证途径选择、中央76格视野、四城、联盟和OOS。
