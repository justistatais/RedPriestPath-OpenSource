# 资源211｜外交头像换行与Better City States兼容

## 公开实现核对

- `Better Leader Icon (UI)`（Workshop 1691629919）与`Extended Diplomacy Ribbon`（Workshop 1360462633）主要扩展外交头像信息和提示；本轮未发现可直接复用的“两排外交头像”实现。
- Firaxis原版`DiplomacyRibbon.lua`采用单排横向Stack和左右滚动；`DiplomacyRibbon.xml`没有Wrap配置。
- Firaxis及本机公开MOD的其他界面已使用`StackGrowth="Right/Left" + WrapWidth + WrapGrowth="Bottom"`，证明ForgeUI原生支持横向Stack向下换行。

## 本项目方案

- 救赎模式加载完整`DiplomacyRibbon_Expansion2`调用链，再包装`RealizeSize`；保留世界议会按钮、外交点击、统计展开和原版事件。
- 头像栏可用宽度按“屏幕中央净化条右边缘—右侧按钮区”动态计算；第一排溢出后向下换行，异常大玩家数时扩大每排容量以保证最多两排且所有头像可见。
- 净化条恢复既有Y=31位置，不再移动本项目HUD迁就头像。

## Better City States冲突与边界

- 订阅目录：`D:\app\steam\steamapps\workshop\content\289070\2495851756`；Mod ID `13E8BCDF-98EC-4C03-3641-72D519B0047C`。
- 该MOD以LoadOrder 321替换`CityStates`，覆盖本项目旧LoadOrder 280包装器，导致三教会虚拟行消失。
- 资源211通过`ModInUse`分流：未启用时包装Firaxis GS界面；启用时先加载`citystates_bst_xp2`，再注入教会行。兼容包装顺序99989，高于321。
- 不修改、不复制Workshop订阅文件。Better布局注释掉`QuestIcon`和`SuzerainLabel`，本项目将两者改为可选控件；其余教会行必需控件仍存在。
- 静态检查不等于游戏内布局通过；两排头像、世界议会按钮和三教会显示需用户实机截图确认。
