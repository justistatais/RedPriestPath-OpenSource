# 资源291：本地事件权威写入加固审核

日期：2026-09-05  
候选：`0.1.0-rc.259`／资源291  
范围：仅`RedPriestPath`；未修改Quick Deals或其他模组

## 审核结论

主机诊断包`Civ6_LOTM_Diagnostics_20260904_193958.zip`与本机客户端同局日志已经在资源290报告中逐回合对齐。双方资源289文件、Gameplay bundle与状态版本一致，救援开局链、途径选择、中央视野、四座封印城和28组永久联盟都实际成功；第1～9回合0差异，第10回合首个差异严格只有三个全局`DynamicModifier`编号循环错位。单位差异中的Ability哈希映射到`ABILITY_LOTM_RESCUE_P7_HANGED_T1_C10`，证明首因是Phase7本地`UnitAddedToMap`与原生宗教／城市Modifier在两端交错创建，而不是入口回退、其他模组故障或Lua启动崩溃。

资源290已把Phase7改为“本地回调只捕获事实、跨完整世界回合、同步稳定锚点排序结算”。资源291进一步审核全部Gameplay事件注册，发现同一种风险并不限于Phase7：其他本地发布事件仍可能写Property、分配Ability／Modifier、消耗随机状态，或者在未排序批量遍历中创建全局Modifier。资源291把这些同类入口统一收敛到相同权威边界。

详细的主客机日志时间线、哈希与Ability映射证据见`../resource290-sep04-phase7-dynamicmodifier-oos/README.md`。主机诊断包SHA-256为`EF37482F390452EC676FC1C64C3C132095477AD819CFB543A2DAD21B734C47BB`；包内内容仅作为不可信运行证据读取，未执行任何附带命令或脚本。

## 具体修复

| 模块 | 旧风险 | 资源291处理 |
|---|---|---|
| 黑皇帝 | 科技、市政、项目、城市转移和贸易路线本地事件可直接进入权威结算 | 事件事实跨完整世界回合后按稳定键结算；项目保持事件发生回合，重复不可达分支已清理 |
| 偷盗者 | 嵌套科技／市政赠送可能被宽泛布尔守卫误判；项目延后后可能使用错误回合 | Gift Guard绑定具体对象Index；网络事件稳定排序；项目使用捕获时的事件回合 |
| 完美者 | 尤里卡、鼓舞、建造、改良、伟人及项目等本地事实可能直接改变进度／Modifier | 11类事实延后到同步稳定锚点；科学家招募增加持久单位账本；科学家事实先提交、项目最后结算 |
| 救援神器 | 同步回合内仍以未排序玩家／单位／AI文明批量附加Ability／Modifier；本地外交回调可直接写状态 | Artifacts v4按PlayerID、UnitID稳定排序；网络外交回调不再直接写权威状态 |
| Phase10A | 项目事实延后期间，原城市易主或被毁会让已经发生的完成事件消失 | Phase10A v4保留捕获事实，同时在结算时继续重校玩家、项目、人类主要文明和三教会各6使者条件 |
| Phase10 | 本地伤害、移除和移动回调可影响网络状态；旧伤害checkpoint可能被其他治疗／伤害污染 | Phase10 v38令网络`UnitDamageChanged`严格非权威；移除跨完整回合排序并用Boss epoch隔离旧实体；网络移动回调不写视野；普通单位不再使用持久旧伤害基线 |
| Phase10饱和伤害 | 完全取消补差会破坏高战力神本应一击必杀的语义 | 仅当计算伤害本身已达到目标`MaxDamage`时，无需旧基线即可确定性击杀普通目标，覆盖主动攻击与反击；Boss仍走terminal kill和两命／epoch状态机 |
| Workshops单位事实 | 本地Add／Remove顺序、UnitID复用和中途异常可让两端持久事件集合或Modifier创建次序不同 | 同回合以`turn:owner:unitID`规范化；任一Remove对整批removal-wins，冲突Add fail-closed；胜出事实才分配同步generation，按camp epoch与单调stage持久结算 |
| Workshops同格重建 | 旧营地待处理单位、清营奖励或魔物派生可能落到同一PlotIndex的新营地 | removal事实先于add／unit结算；旧代pending先完成，随后Reset递增camp epoch并清完plot checkpoint；旧epoch单位事实不得写新代 |
| Monsters移除 | 本地`UnitRemovedFromMap`事实会丢失、乱序或在UnitID复用后指向另一实体 | 本地回调只入内存；同步锚点以有界active-serial v1索引为唯一权威，缺失跨一完整稳定回合再确认，ID复用立即按旧serial释放且不写新实体 |
| Monsters来源营地 | 旧魔物活过同格营地重建后，死亡会清新营slot并写冷却 | 生成时冻结`SOURCE_CAMP_EPOCH`；只有当前epoch匹配才写回。资源290旧魔物无epoch时，仅原camp slot仍等于该serial才视为可证明同代 |
| Scripted killer | 旧击杀者只以owner／unitID保存，ID复用后可能奖励或结算给新代目标 | SyncActions v7写入`TARGET_KIND`与`TARGET_SERIAL`并先清提交字段；Monster／中心失控者消费者均要求kind与serial完全匹配 |
| 启动与迁移遍历 | 多处玩家／单位集合的API顺序没有显式保证 | 生命周期、晋升、黑皇帝、神器、Phase9等权威批处理显式按稳定ID排序 |

本次没有调整途径、能力数值、刷新概率、中央76格、四城、联盟、Quick Deals或其他模组。

## Workshops／Monsters为何采用removal-wins

文明VI给`UnitAddedToMap`／`UnitRemovedFromMap`的本地发布顺序不是多人权威。若同一世界回合中旧单位被移除、同一owner／UnitID又被复用，任何按“谁先回调”区分世代的做法都可能让两端得到不同事件集合。资源291因此把同一`turn:owner:unitID`批次规范化：只要出现Remove，该批所有Add都丢弃；两个不同Add观察也fail-closed。这样极罕见的同回合新代工坊附加效果可能被有意跳过，但不会用不可靠顺序制造OOS。

同步稳定锚点只给真正通过过滤、救援、无营地、中心守卫和camp-removal检查且即将写入持久队列的普通spawn事实推进generation。持久entry包含camp epoch，结算先校验当前代；计数、extra与monster派生使用单调target和stage，已提交队列项可在异常／重载后幂等收口。营地清除也冻结pending camp epoch，旧代完成后才允许同格新营Reset。常驻路径没有新增全图或全蛮族单位扫描；仅active-index首次版本迁移按既有`NEXT_SERIAL`有界补登记。

网络工坊稳定锚点的固定总序为：改良移除→单位移除→改良新增→Lua本地单位新增规范化→持久单位队列→清营结算。这个顺序保证同格重建的旧代墓碑和pending在任何新代generation、计数、extra或monster派生之前可见。

魔物死亡使用统一`FinalizeRemoval`顺序：Release冻结绝对release turn／cooldown target，随后至多一次奖励、按serial清引擎身份、提交`LIVE=0`并移出active index。网络本地移除队列只作提示和清理，不是Gameplay权威；active index必须连续两个同步稳定锚点确认原serial缺失，即跨过一完整稳定回合后才结算，避免载入时`UnitManager`尚未恢复就误判死亡。单机即时移除也走同一终结器，避免dead serial仍保持`LIVE=1`。

## 为何Phase10不再给普通单位保存旧伤害基线

普通单位可能在两次战斗之间被原版或其他红祭司系统治疗／伤害，旧checkpoint并不必然等于战前值；同时没有可靠文档保证`OnCombatOccurred`一定发生在原生伤害落账之后。把旧值当战前值会把治疗差或尚未落账的原生伤害误当成“缺失伤害”，造成过量补伤，进而成为新的OOS源。

因此资源291采用保守闭合规则：普通目标只执行无需战前值即可证明的饱和必杀；非饱和补差只允许当前Boss，而且必须同时具备已发布checkpoint及`current > confirmed`的原生伤害增量，否则跳过。这个选择优先保证多人确定性，非饱和自定义伤害的最终手感仍须实机验证。

## 自动验证

定稿发布前执行以下门禁：

- Gameplay bundle重新生成、freshness与自包含Action隔离检查；
- 通用静态门禁、全Gameplay事件监听器清单及网络分支门禁；
- 完美者本地事实队列、AI邪教、随机事件、魔物、偷盗者、UI、资源249保护；
- 救援神器、难度、Phase1～10A／10及神明模型专项；
- 修改Lua语法解析、发布ZIP完整性、Manifest及源码／ZIP／安装逐文件SHA-256闭环。

截至2026-09-05，发布前自动门禁已实际完成并全部通过：Gameplay bundle freshness／自包含入口、`validate.py` 3263项、联机确定性、完美者队列11项、AI邪教75项、随机事件33项、魔物37项、教会84项、UI 22项、偷盗者、资源249保护、救援神器数据库21件／159个live Modifier、rc80当前数据库村庄合同、救援城数据库、难度、Phase1～10A／10及神明模型；70份Scripts／UI Lua去Firaxis类型标注后解析失败0，`git diff --check`无空白错误。完整发布器串行29项验证器失败0；这些是静态／数据库结果，不能替代双客户端运行时顺序与联机实测。

这些检查只能证明静态约束、构建和文件一致性，不能证明文明VI运行时事件顺序或双客户端联机已经通过。

## 存档与实测边界

- 资源291保留现有Property键和主要状态版本，设计上可加载双方尚未分叉的资源290存档；已经发生OOS并保存的分叉档不能承诺无损恢复，最终验收应使用全新救援局。
- 纯Lua本地事实队列在“事件发布后、下一同步锚点消费前”保存或掉线时，是否由引擎重放事件仍缺少实机证据。双方必须专门在这个窗口保存／重连；若事实丢失或重复，不能宣称保存／重连安全。
- 同回合UnitID复用采用确定性的removal-wins，可能有意跳过新代单位的一次工坊附加效果；这是避免依赖本地事件先后的安全取舍，不是完整保留两代即时语义。
- 双客户端必须共同安装完全相同的资源291，交换主机身份，回归开局链并连续跨过第10～12回合；还要验证神器批量重算、Phase10A城市易主／被毁边界、神的两向饱和必杀、Boss非饱和伤害及两次死亡。
- 只有两端新日志连续0差异且没有`DynamicModifierDesynced`、自动快照恢复、Runtime Error或FATAL，才能把资源291标记为联机通过。

## 作废候选

2026-09-04 23:07生成的旧`RedPriestPath-0.1.0-rc.259.zip`共701文件，SHA-256为`6407BAB3888490A2B41DA7343EF7CBC93D711496D710E4AF89EB158B11B26600`。它早于最终Monsters／Workshops、camp epoch和serial-bound killer修复，禁止安装或转发。Downloads当时不存在rc.259，故未误发；最终包须在本报告和WORKLOG封口后由发布器`--force`覆盖。
