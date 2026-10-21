# rc.356／资源388：寄生与时之虫高级建城

## 规则
- 救赎模式序列4及以后：途径持有者站在合法建城地块，通过专用建城按钮建立己方城市。不再要求蛮族营地。成功后持有者死亡，5回合后复活。
- 序列1及以后：时之虫通过同类按钮建城，原单位保留；确认成功后冷却3回合。
- 两种能力的新城额外获得3人口和远古城墙。原版 Hic Sunt Dracones 的异大陆建城加成是额外3人口，不自带城墙；本次复用原生城市人口和免费建筑效果，不要求异大陆。其他建城加成仍由游戏处理。
- 正常开拓者建城、仅经过时之虫旧位置的城市、其他文明城市不获得本次额外效果。普通模式未接入。

## 证据及静态覆盖
- 改前日志：Reports/rc356-before-change-logs。资源387该局第52回合成功5→4，但专用按钮和Gameplay仍要求完整蛮族营地，日志未见建城请求。
- 原版参考：Expansion2/Data/Expansion1_Moments.xml，COMMEMORATION_EXPLORATION_GA_NEW_CITY_POPULATION，Amount=3；Base/Assets/Gameplay/Data/GreatPeople_Scientists.xml的MODIFIER_SINGLE_CITY_GRANT_BUILDING_IN_CITY_IGNORE。
- test_rc356_advanced_cities.py：实际Lua 5.1函数，覆盖无营地、成功/失败、同步/异步/重入、消费原生执行单位前的回调、成功后返回失败、每城一次奖励、时之虫保留及冷却、非请求城市不发奖、专用UI分流和原生SQL作用域。旧rc347门控测试按用户新规则更新，rc346不可变基线仍保留。
- 这不是游戏内或多人验收；原生C++建城和modifier行为不由Lua替身证明。

## 游戏实测
1. 完全退出游戏再启动；日志确认resource388。新局救赎序列9不显示此建城能力。
2. 序列4持有者选择合法空地，按钮提示额外3人口和远古城墙。成功后确认新城人口（基础1人口时合计4）、城墙、持有者死亡及5回合后复活、消化+1。
3. 在城市间距不足、非法地形/所有权地块尝试：不得建城、死亡、消化或扣除当回合机会；日志NATIVE_PLACEMENT说明原生拒绝。
4. 序列1时之虫合法地块建城：同样+3人口、远古城墙，原单位不消失且结束移动；第3回合重新可用。原版无限制建城按钮不得出现。
5. 普通开拓者新城不获得本次人口和城墙；重复开关面板、存读或重复事件不再发一次奖励。多人只由同步Gameplay确认结果。
6. 若原生效果异常，保留Lua.log中的advanced city effect（来源、city、modifier、accepted）、camp conversion committed或time worm found committed。

不新增旧档迁移、不扫描既有城市补发；用户已暂停旧档兼容。本轮待游戏实测。
