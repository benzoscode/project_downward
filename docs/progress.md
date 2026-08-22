# 进度与计划 — 《downward》

> 交接文档：新对话从这里恢复上下文。最后更新：2026-08-18（机关三批/tilebuild 合入后）。
> 详细规范见根目录 `AGENTS.md`；架构细节见 `godot_project/docs/architecture.md`。

## 1. 当前状态快照

- **分支**：本地与远程 `develop`、`tilebuild` 均已同步到最新（推送已恢复，远程无残留分支）。
- **里程碑**：M0/M1 已验收；M2-M8 **内容全部完成并通过基础验收**（`[~]` 待最终归档）。M9（结局关卡）未开始；M10（打磨）可裁剪。
- **自动验证**：`tools/run_verify.ps1` 一键复验，当前 **88 项全绿**（玩家 8 / 相机 2 / TileSet / 机关 5 / 穿越 8 / 光照 4 / 二段跳 4 / 老鼠 11 / 机关二批 8 / 机关三批 7 / Boss 12 / 房间 12）。
- **可玩入口**：
  - `scenes/main.tscn`（F5）：从 room_01 开局，12 房间灰盒可流通
  - `scenes/test/boss_lab.tscn` / `mechanism_lab.tscn` / `demo_room.tscn`（F6 单开）
- **策划协作**：`tilebuild` 分支进行中（room_01/03/04 已有搭建稿并合入）；搭建指南 `godot_project/docs/关卡搭建指南.html`。

## 2. 已实现机制速查

| 系统 | 入口 | 要点 |
|---|---|---|
| 玩家控制器 | `scripts/characters/player.gd` | 行走4/奔跑6(按住Shift)/跳3格/二段跳5格(靴)/攀爬3格锁梯子中线/水域/检查点重生/`input_delay`（致幻） |
| 老鼠 | `scripts/characters/mouse.gd` + `ControlManager` | 5.2格/秒、2+1.5格跳、16×8判定（正式素材 idle12帧/run9帧/跳跃上下单帧）、窄缝、0.8s 延迟参数 |
| 灯光 | `scripts/characters/lamp.gd` + `LightSystem` | F 开关（灯口对齐素材灯笼位）、60°/6格、鼠标跟随、`is_point_lit`/`is_point_lit_ambient`/`has_clear_line` |
| Boss | `scripts/characters/boss.gd`（M7） | 五状态机、老鼠优先、接触扑杀、搜索10s超时；手感待迭代（见 §5） |
| 机关通信 | `MechanismBus` | `trigger/release/pulse`（脉冲=事件型连发）+ `is_triggered`，StringName ID，状态跨重生保留 |
| 房间连通 | `RoomManager`（M8，方案 D 无注册表） | 出口直存 .tscn 路径、检查点（入口自动存档+checkpoint 积木）、相机钳制同步+瞬移 |
| 积木 21 个 | `scenes/interactables/` | 手册：`docs/building_blocks.md`；图文指南：`docs/关卡搭建指南.html` |
| TileSet | `assets/tiles/tileset_cave.tres` | 12 源（1 泥土/2 石质/5 石砖带碰撞遮光，3/4/6 装饰，7 水面，8-11 水体动画瓦片）；改动走 `tools/build_tileset.gd` |
| 主角素材 | `assets/characters/` + `assets/props/` | 正式素材：主角待机/奔跑/跳跃/攀爬全状态（2026-08-20）；鼠鼠 idle/run/跳跃；门/按钮/梯子/吊桥/交替平台/压力板/水晶/光球/物品图标 |
| HUD | `scripts/autoload/hud.gd` | 占位：拾取弹窗+图标栏+`show_message` 文字弹窗（多行），M10 重做 |

## 3. 下一步计划（按依赖顺序）

1. **M9 第 12 房间整合与结局**（下一个开发任务，AI 灰盒）：三层结构（潜行→追赶+三项操作→老鼠诱敌+宝石嵌入+冲刺结局）；Boss 追赶路径记录回放、光敏屏障 60s 四档减弱、房间内检查点（第二层入口）、Boss 重置；**顺带在真实关卡里迭代 Boss 手感**（§5 遗留）。新分支 `feat/m9-finale`。
2. **策划人工环节**（并行）：room_01~11 正式搭建（灰盒装修/扩建到全尺寸），tilebuild 分支协作。
3. **M10 打磨**（可裁剪）：HUD 重做、音效、粒子、结局演出精修。

## 4. 关键设计决策（勿轻易推翻，详见 decisions.md）

- 渲染：480×270 原生 + 整数倍缩放 + **亚像素渲染**（不开像素吸附！）+ 全局物理插值
- 手感调校（2026-08-17/18 用户拍板，覆盖策划案）：行走 4 格/秒、按住 Shift 奔跑 6 格、攀爬 3 格、能见度收窄（自发光 1.5 格+灰盒 0.10）、灯 energy 2.6、攀爬锁梯子中线
- 灯光：鼠标实时跟随；灯口对齐素材灯笼位（本地 (6,2)，随朝向镜像）
- 致幻：输入延迟（`player.input_delay`）
- 碰撞分层：地形/门=层1、玩家=层2、老鼠=层3、Boss=层4（值8）、交互区 mask=6
- 房间系统：方案 D 无注册表，出口直存场景路径；检查点=入口/检查点积木
- 灰盒房间为紧凑测试尺寸（40×17，room_12 为 90×34），正式房间装修时可扩建

## 5. 遗留问题

### 5a. 2026-08-20 素材批待用户确认的决策点（AI 自行拍板，用户将一并处理）

- [ ] 跳跃素材 16×26 比标准帧高 2px，切帧时脚底 ±1px 跳动未做补偿（可统一素材尺寸或加偏移）
- [ ] 鼠鼠判定 16×8 取身体不含尾巴；尾巴不参与碰撞
- [ ] 攀爬素材无灯光差分（只有一套图）；帧率 10→16fps 为主观调校
- [ ] 坠落"×0.5"实现为**下落重力减半**（1.4→0.7）：同高度落地速度实为原来 0.707 倍、下落时间约 1.4 倍；若要落地速度严格减半应改 0.35
- [ ] 门素材 16×48 比原占位窄：碰撞同步改 16×48，已建房间 2 格宽门洞会露 16px 缝
- [ ] 门"正确/错误"两态素材未接线（留给 M9 宝石门/顺序机关反馈）
- [ ] 狮子头按钮无按下差分图，按下态=同图+压暗 0.7
- [ ] 彩色按钮映射：红/蓝直用，琥珀用黄图，绿色无素材回退基础图+调色
- [ ] 双压力板门复用 dual_button_door.gd，松板后 1s 宽限关闭（非立即关）
- [ ] 摇杆吊桥松开立即缓降（无停留窗口），lower_speed 20px/s 为拍脑袋值
- [ ] 灯光暖橘黄色值 (1, 0.68, 0.32) 为 AI 自选；AmbientLight 自发光未改色
- [ ] 交替平台 A/B 两组共用同一套显现/消失素材（原 red/green 区分丢失），靠相位区分
- [ ] 吊桥吊绳素材（左/右吊绳）未接线：桥升降时绳长变化，需动态拉伸方案
- [ ] 石门宝石素材（door_gem_* 空/实 3×2）已入库但未接线，留给 M9 三宝石之门嵌入凹槽
- [ ] 光球贴图按主色调映射（红/蓝/黄），tint 灯色仍保留；灰/紫等其它色调回退黄球
- [ ] 压力板小型（仅老鼠）用 16×16 素材缩小 0.6 显示，与原小尺寸占位观感不同

### 5b. 历史遗留

- [ ] **Boss 手感未达预期**（用户反馈，暂缓）——M9 在真实关卡上下文中迭代
- [ ] 重生时敌人不复位（同房间死亡 Boss 保持原位/状态）——用户拍板暂缓，M9 视需要再议
- [ ] 光敏水晶在黑暗中难发现（可加微弱自发光轮廓，用户暂缓）
- [ ] 灯光朝向混合方案（朝向+鼠标自动切换）备选未做
- [x] ~~跳跃/攀爬动画待补画~~（2026-08-20 已实装：跳跃上升/下落单帧、攀爬 12 帧上爬序列下爬倒放）
- [ ] paint/capture 工具 `--script` 模式无 Autoload，含 Autoload 引用的脚本在其中编译失败——重生成 mechanism_lab 等需走宿主模式（decisions.md 2026-08-17）
- [ ] 策划同事环境是 Godot 4.6，本仓库用 4.7.1——建议统一，否则 project.godot features 标记会反复被改

## 6. 常用命令（godot_project/ 下）

```powershell
$godot = "C:\softwares\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe"
& $godot --headless --import                                    # 静态检查
powershell -ExecutionPolicy Bypass -File tools/run_verify.ps1   # 全部机制断言（应 VERIFY PASSED）
& $godot --headless --quit-after 120 res://scenes/main.tscn     # 冒烟
```
