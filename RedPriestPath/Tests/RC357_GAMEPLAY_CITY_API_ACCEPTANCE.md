# rc357／资源389：点击建城无反应

- 原始证据：Reports/rc357-before-change-logs/Lua.log。资源388在回合52重载，点击三次均为 `advanced city refused reason=FOUND_CITY_API`。UI/同步路由已通，故障位于Gameplay没有UI建城操作接口。上一版测试替身错误地同时提供两种上下文API；本版专门以这些API为nil重现旧版失败。
- 修复：复用本项目Phase2及Firaxis AustraliaScenario的同步 `player:GetCities():Create(x,y)`，创建后通过 `CityManager.GetCityAt`核实城市。创建过程中不发高级奖励，待原生初始化返回后确认。返回nil/false或抛错但城市已经真实创建时，不误当失败；未创建则清pending，不死亡、不冷却。
- 合法性：陆地、可通过、地貌Settlement、非自然奇观、无城市/区域/奇观、非外国地块，以及数据库CITY_MIN_RANGE范围内已有城市间距。不同陆块缩短1格；GetArea不可用则保守使用同陆块间距。只检查当地邻域，不扫描地图、全部单位或城市。
- 不生成临时建城单位。普通持有者和时之虫仍无原版无限制建城按钮。高级城额外3人口/远古城墙、持有者5回合复活、时之虫保留且冷却3回合不变。
- 点击日志：UI提交、parasite/time worm city command、失败reason，或 `advanced city verified ... api=PlayerCities.Create`。非法地块或创建失败增加中英文本浮字，提示城市太近、外国领土等原因。
- 单元测试运行实际Lua 5.1，覆盖旧版故障正对照、缺失UI API仍能创建、合法性、无全扫、城市核实、双能力、回调重入/重复、失败回滚、存读收据。引擎C++行为、原生modifier生效及双端同步仍待游戏实测。

实测：完全重启资源389，序列4持有者选合法空地点击寄生，应建城、额外3人口及远古城墙，死亡且5回合复活；距城市太近应显示原因且不死亡。序列1时之虫同样建城，原单位保留、3回合冷却。保留日志核对上述提交和确认点。

本轮数据库另有 `CSACore / Data/Bug_Amon_StealAbility.sql` 语法错误及官方CurrentClickouts重复本地化，已记录但不属于本次点击在FOUND_CITY_API退出的原因；未擅自修改其他模组。
