# 原版资产映射

本目录不包含任何复制出的游戏模型、贴图、图标或音频。

- `LOTM_RP_Units.artdef` 为自定义单位建立 ArtDef 条目，引用原版 `Units.artdef` 中的 `Scout`、`ScoutDog`、`Scout` 队形、侦察兵音频交叉引用和单体远古登船外观。
- `LOTM_RP_Icons.xml` 为红祭司和完美者分别注册独立的一格Atlas；项目、常规单位图标、战争迷雾、旗帜黑白名和肖像均使用对应途径标志，不再映射原版侦察兵。
- `LOTM_RP_RedPriestGameIcon*.dds` 与 `LOTM_PP_PerfectGameIcon*.dds` 覆盖官方项目、单位和肖像所需的22/30/32/38/50/70/80/95/200/256像素尺寸。
- `LOTM_RESCUE_{FOOL,NIGHT,STORM}_GuardianGameIcon*.dds` 为阶段3守卫提供同样十档单位尺寸；圆外透明，圆内使用对应教会底色和黑色纹路，避免把教会面板原图的不透明黑色方框带入地图旗帜和战斗预览。
- `LOTM_RP_RedPriestMarkCentered40/384/512/640/768.dds` 由用户提供的红祭司标志原图确定性居中缩放并生成透明通道；40像素版本供顶部入口使用，其他四档供不同分辨率的序列0过场使用。
- `LOTM_RP.dep` 只声明原版 Unit library 包依赖，不携带原版资源文件。

如果游戏更新改变原版 ArtDef 版本或 Atlas 索引，应在游戏内重新检查单位模型、旗帜和肖像。
