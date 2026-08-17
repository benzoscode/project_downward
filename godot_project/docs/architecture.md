# 架构总览 — 《downward》

> 每个里程碑完成后更新本文档。当前对应里程碑：**M0 工程地基**。

## 1. 技术基础

- Godot 4.7 stable，GDScript 全静态类型
- 渲染：480×270 原生 + 整数倍缩放（viewport 拉伸 / keep / integer），Nearest 过滤；**不用像素吸附**（亚像素渲染，决策见 decisions.md 2026-08-16）
- 物理：全局开物理插值（`physics/common/physics_interpolation=true`），相机与物理体移动在 144Hz 屏下保持平滑
- 逻辑网格：1 格 = 16px，房间 120×67 格（1920×1080 逻辑）

## 2. 目录与职责

见仓库根目录 `AGENTS.md` §4。关键约定：

- `scenes/` 与 `scripts/` 目录层级镜像
- 机关积木在 `scenes/interactables/`，房间在 `scenes/rooms/`（策划搭建）
- `tools/` 为开发工具，不进游戏包

## 3. Autoload

| 单例 | 职责 |
|---|---|
| `GameState` | 道具持有（灯/靴/哨/钥匙/三宝石）、当前房间、检查点位置；发 `item_acquired` / `checkpoint_updated` 信号 |
| `MechanismBus` | 机关通信总线：`trigger/release/is_triggered` + `triggered/released` 信号；机关状态跨重生保留（decisions.md 2026-08-16） |
| `LightSystem` | 光照判定：`is_point_lit(point)`（射程+锥角+物理射线）+ `is_point_lit_ambient`（环境光）+ `has_clear_line`，供水晶/Boss 复用 |
| `ControlManager` | 双体控制（M5）：Q 召唤/收回、R 切换、老鼠死亡 5s 冷却、pcam 优先级切换；`force_recall` 供转场主动收回（免冷却） |
| `RoomManager` | 房间切换（M8）：`goto_room` 淡入淡出、入口落位、检查点重生（可跨房间）、玩家实例跨房间托管、pcam 钳制同步 |
| `HUD` | 占位 UI：道具获取弹窗 + 持有图标栏（M10 重做） |

## 4. 房间模板（room_base.tscn）节点树

```
RoomBase (Node2D) + RoomBase.gd (@tool：编辑亮 / 运行时暗)
├── CanvasModulate      # 亮度由 RoomBase 脚本按编辑/运行态切换
├── TileMapTerrain          # TileMapLayer：物理碰撞地形
├── TileMapDecor            # TileMapLayer：无碰撞装饰
├── TileMapMechanismMarkers # TileMapLayer：机关占位标记
├── Mechanisms          # 机关积木实例挂这里
├── Characters          # 玩家/老鼠/Boss 挂这里
├── Lights              # 环境光源挂这里
├── SpawnPoint          # 出生点
├── ExitTrigger         # 出口触发区（M8 接通房间过渡）
└── Camera2D            # 限制 0,0 ~ 1920,1080
```

TileSet：`assets/tiles/tileset_cave.tres`，12 个 source（0 占位 / 1 泥土 / 2 石质 / 5 石砖，带碰撞+遮光；3 装饰16px / 4 装饰32px / 6 草丛 / 7 水面 / 8-11 水体动画瓦片，无碰撞）；布局改动走 `tools/build_tileset.gd`，分区表见 building_blocks.md。

## 5. 输入映射

| Action | 键鼠 | 手柄 |
|---|---|---|
| `move_left` / `move_right` | A/D、方向键 | 十字键左右、左摇杆 X 轴 |
| `move_up` / `move_down` | W/S、方向键 | 十字键上下、左摇杆 Y 轴 |
| `jump` | 空格 | A（南键） |
| `interact` | E | X（西键） |
| `toggle_lamp` | F | Y（北键） |
| `whistle` | Q | LB |
| `switch_control` | R | RB |

手柄灯光瞄准（右摇杆）在 M2 光照系统中适配，不占用 Input Map action。

## 6. 开发工具

| 工具 | 用途 |
|---|---|
| `tools/generate_placeholders.ps1` | 生成全部占位素材（尺寸规范见 AGENTS.md §7） |
| `tools/verify_smoke.ps1` | headless 导入检查 + 场景冒烟，CI 式退出码 |
| `tools/capture.gd` | 截图：加载场景跑 N 帧存 PNG（输出到 `tools/out/`，不入库） |

（状态机、光照系统、机关协议、Boss AI 等随里程碑补充）

## 7. 角色与相机（M1）

- `scenes/characters/player.tscn`（class `Player`）：CharacterBody2D，判定 12×20
  - 移动：3 格/秒，加速度 400 / 减速度 550 px/s²（惯性手感）
  - 跳跃：3 格高，到顶点 0.35s；下落重力 ×1.4；土狼 0.1s + 缓冲 0.1s
  - 参数推导：重力/初速度由"跳跃高度 + 到顶点时间"反推（`_recalculate_jump`），策划只调直觉参数
  - 自带 2 格半径微光 `AmbientLight`（关灯状态的自发光，策划案 §二(二)1）
- `scripts/rooms/room_base.gd`（class `RoomBase`，@tool）：**编辑亮 / 运行时暗**分离——编辑器 `editor_brightness`(0.45) 供搭建，运行时 `game_darkness`(0.05) 供游戏；两个颜色均可在 Inspector 调
- 相机（Phantom Camera 插件，v0.11.0.3）：
  - 房间内 `Camera2D`（limit 0,0~1920,1080）→ 子节点 `PhantomCameraHost`（host 脚本）
  - 玩家身上 `PhantomCamera2D`（top_level，priority 10，SIMPLE 跟随，`follow_target=..`，`follow_damping` 0.15s，snap_to_pixel）
  - M5 切老鼠时：新增/切换老鼠的 PhantomCamera2D 或改 priority 即可
- 演示房间 `scenes/rooms/demo_room.tscn` 由 `tools/paint_demo_room.gd` 生成（tile_map_data 二进制格式由引擎序列化，不手写）；出生点贴近地面

## 8. 自动验证

| 脚本 | 断言内容 |
|---|---|
| `tools/verify/verify_player.gd` | T1 起步惯性 / T2 满速 48px/s / T3 惯性停步 / T4 跳高 3 格±3px / T5 土狼时间 / T6 跳跃缓冲 |
| `tools/verify/verify_camera.gd` | 相机被 PhantomCamera 接管、收敛到玩家 ±6px |
| `tools/verify/verify_mechanisms.gd` | 按钮→总线→门开关、一次性按钮、拾取物、宝箱 |
| `tools/verify/verify_traversal.gd` | 水中减速/半透明、梯子攀爬与跳出、触刺重生、死后机关状态保留 |
| `tools/verify/verify_lighting.gd` | 水晶 2s 激活 / 遮挡不激活 / 关灯不激活 / 超程不激活 |
| `tools/verify/verify_double_jump.gd` | M4：无靴 3 格 / 有靴 5 格 / 0.2s 窗口 / 重置水平速度 |
| `tools/verify/verify_mouse.gd` | M5：召唤/切换/相机/窄缝/0.8s 延迟/双档压力板/死亡冷却/收回（11 项） |
| `tools/verify/verify_mechanisms2.gd` | M6：交替平台/摇杆平台/双按钮门/滞后/草丛/顺序机关/虚空平台/玩家输入延迟 |
| `tools/verify/verify_boss.gd` | M7：五状态全部转换路径、老鼠优先级、双扑杀、搜索 10s 超时、环境光暴露、黑暗安全（12 项） |
| `tools/verify/verify_rooms.gd` | M8：12 房间 BFS 连通/入口存在性、能力门结构、过渡落位与检查点、出口触发、同/跨房间重生、钥匙门、pcam 钳制（12 项） |
| `tools/verify/verify_tileset.gd` | TileSet 五分区、碰撞配置、32px 装饰格 |

运行：`tools/run_verify.ps1`（退出码即结果，人类可一键复验）。需要 Autoload 的验证走 `scenes/test/verify_host.tscn` 宿主（`--script` 模式无 Autoload）。

## 9. 机关积木（M3）

- 通信：`MechanismBus` 总线 + StringName ID（见 decisions.md 2026-08-16）
- 积木清单与参数：`docs/building_blocks.md`「机关积木（M3 第一批）」
- 玩家侧能力：`die()`（回 `spawn_point` 组标记）、`set_interactable/clear_interactable`、`enter/exit_water`、`enter/exit_ladder`；积木经 `is_in_group("player")` 判定后调用
- 演示房间 `scenes/rooms/demo_room.tscn` 由 `tools/paint_demo_room.gd` 生成：地刺坑 → 水池 → 按钮开门拿宝石 → 梯子开宝箱

## 10. 光照系统（M2）

- **玩家灯**：`player.tscn/Lamp`（`scripts/characters/lamp.gd`）：F 开关（需 `has_lamp`），60° 锥形（贴图 `light_cone.png`，顶点在图中心）、6 格射程、方向跟随鼠标；`PointLight2D.shadow_enabled` + TileSet 遮光层（实心瓦片全格 Occluder，多边形模式——SDF 模式实测异常）
- **LightSystem**（Autoload）：`is_point_lit(point)` = 射程内 + 锥角内 + 物理射线无遮挡；供光敏水晶、M7 Boss 感知复用
- **光敏水晶**：`scenes/interactables/light_crystal.tscn`，照射 2s 激活发 `target_id`，带充能渐亮反馈
- **环境**：房间 `game_darkness` 0.05 + 玩家 2 格自发光（AmbientLight）
- 已知取舍：贴地掠射的光锥会被地面自身遮光裁剪（物理合理），视觉调试能量/衰减在 Lamp 与贴图两侧

## 11. 双体与能力（M4/M5）

- **碰撞分层**：地形/门=层1、玩家=层2、老鼠=层3（值4）；交互区 `collision_mask=6`（2|4）同时感知两者，人鼠互不碰撞
- **老鼠**：`scenes/characters/mouse.tscn`（class Mouse），5.2 格/秒、2+1.5 格跳、6×6 判定、`input_delay` 采样回放实现
- **操控切换**：ControlManager 管召唤/收回/切换/冷却；玩家与老鼠各有 `control_active` 门控输入；相机靠老鼠自带 pcam 的优先级（11 压过玩家 10）
- **二段跳**：player.gd，`has_boots` 门槛、0.2s 防误触（按按键时刻判定）、重置空中水平速度
- **玩家致幻输入延迟**：`player.input_delay`（采样回放，与老鼠同构）

## 12. 机关积木二批（M6）

交替平台 / 摇杆平台 / 双按钮门 / 滞后组件 / 草丛光透 / 水滴顺序机关（color_button + sequence_controller，组 `seq_<id>` 注册）/ 虚空平台。手册见 building_blocks.md。
综合试验场：`scenes/test/mechanism_lab.tscn`（由 tools/paint_mechanism_lab.gd 生成），长跑道串联全部能力。

## 13. Boss（地底猎食者，M7）

- `scenes/characters/boss.tscn`（class `Boss`，@tool）：CharacterBody2D，128×128 剪影，判定 96×96；碰撞层 4（值 8），mask=1 只与地形碰撞；`KillZone`（Area2D，mask=6）感知玩家/老鼠接触
- **五状态状态机**（`scripts/characters/boss.gd`，转换条件按策划案 §二(四)2）：巡逻 Patrol → 警戒 Alert → 追击 Chase → 搜索 Search →（超时回巡逻）；警戒/追击/搜索中老鼠 ≤6 格 → 分心 Distracted（老鼠优先，§二(四)3 优先级规则）
- **感知**：玩家开灯（`LightSystem.is_lamp_on`，不看锥形朝向——"感知范围内有光源存在"即暴露）或暴露于环境光（`LightSystem.is_point_lit_ambient`）；感光判定含 Boss↔目标地形遮挡射线（`LightSystem.has_clear_line`，与遮光层同几何）
- **扑杀**：CHASE 状态接触玩家 → `player.die()`；DISTRACTED 状态接触老鼠 → `mouse.die()`（5s 冷却复用 ControlManager），随后转搜索；其余状态接触无害（盲眼未察觉）
- **环境光源积木**：`scenes/interactables/ambient_light.tscn`（熔岩裂缝/荧光苔藓载体），注册到 LightSystem 参与 `is_point_lit_ambient` 判定
- **移动**：巡逻 1.5 / 警戒 2.5 / 追击 4.5 格/秒（追击必须快于玩家 3 格/秒）；追击 = 直线 + 撞墙/目标在高处时跳 2 格绕障（milestones M7 允许简化，不做完整寻路）；巡逻路径可选 `patrol_route`（Path2D 往返），缺省在出生点 ±`patrol_half_extent_tiles` 内往返
- **编辑器可视化**：@tool 绘制追击 8 格（红）/警戒 12 格（黄）/分心 6 格（紫）感知圈 + 巡逻路径；触须三态用 modulate 五色占位（未来换正式动画）
- 试验场 `scenes/test/boss_lab.tscn`（由 tools/paint_boss_lab.gd 生成）；五状态截图工具 `tools/capture_boss_states.gd`（走 verify_host，输出 tools/out/）
- 注意：Boss 感知查询经组 `player`/`mouse` 与根节点取 LightSystem，**不直接引用 Autoload 名**——--script 模式（无 Autoload）下编译期解析会失败（paint 脚本约束）

## 14. 房间连通与检查点（M8）

- **主场景**：`scenes/main.tscn`（F5 从 room_01 开局）；demo_room/labs 仍可 F6 独立运行，RoomManager 会收养场景自带玩家
- **RoomManager**（Autoload，**无注册表**——方案 D，decisions.md 2026-08-17）：
  - `goto_room(scene_path, entrance_id)` 淡出(0.4s)→黑场(0.15s)→切场景→落位→淡入(0.4s)，转场中锁玩家输入并主动收回老鼠（免冷却）
  - 场景路径取自实例的 `scene_file_path`，新增房间**零代码零登记**：丢进 `scenes/rooms/` 即可被指出口
  - 玩家为**持久实例**：切场景时从旧场景摘下挂入新场景 `Characters`；场景无玩家则自动实例化
  - **检查点**：进场景自动 `GameState.set_checkpoint(路径, 入口位置)`；`checkpoint.tscn` 积木提供房间中部存档位；`player.die()` → `respawn()`：同场景直接落位，跨场景重载；无检查点上下文（独立测试场景）回退旧 spawn_point 行为
  - **相机**：进场景/重生后把 Camera2D limit 同步到 pcam（遗留修复），并调 pcam `teleport_position()` 瞬移对准玩家（跳过 0.15s 阻尼摇镜）
- **场景协议**（策划手册见 building_blocks.md）：场景根 = RoomBase 脚本（`player_input_delay` 场景级致幻配置）；入口 = `Entrance_<id>` Marker2D；出口 = `room_exit.tscn`（`target_scene` 在 Inspector 用文件选择器选 .tscn，`target_entrance` 填入口 id；编辑器内青色描边+目标文字）
- **钥匙门积木** `key_door.tscn`：`GameState.has_key` 开启（第 4 房间宝箱 → 第 3 房间右上角门 → 12 房）
- **12 房间灰盒骨架**：`tools/paint_rooms_graybox.gd` 批量生成 `scenes/rooms/room_01..12.tscn`（镜像 room_base 结构）。连接图：1→2→3→4→5→6→7→8→9→11；7⇄10 梯子；5→4 水体秘密通道；11→狭长通道→3 回环；3 钥匙门→12。能力门结构：3 房 5 格高墙（二段跳）/钥匙门、9 房老鼠窄缝、8 房地刺床。**尺寸为紧凑测试规格** 40×17 格（room_12 为 90×34 三层空壳），灰盒亮度 0.3 便于观察；策划案正式房间 ≥120×67，装修阶段按出入口相对关系扩建（decisions.md 2026-08-17）。**策划在灰盒上装修，出入口结构不动**
