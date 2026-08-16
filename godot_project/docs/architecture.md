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
| `GameState` | 道具持有（灯/靴/哨/三宝石）、当前房间、检查点位置；发 `item_acquired` / `checkpoint_updated` 信号 |
| `MechanismBus` | 机关通信总线：`trigger/release/is_triggered` + `triggered/released` 信号；机关状态跨重生保留（decisions.md 2026-08-16） |

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

TileSet：`assets/tiles/tileset_cave.tres`，图集 4×2 块 16×16，上行 4 块带碰撞、下行 3 块纯装饰。

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
| `tools/verify/verify_tileset.gd` | TileSet 五分区、碰撞配置、32px 装饰格 |

运行：`tools/run_verify.ps1`（退出码即结果，人类可一键复验）。需要 Autoload 的验证走 `scenes/test/verify_host.tscn` 宿主（`--script` 模式无 Autoload）。

## 9. 机关积木（M3）

- 通信：`MechanismBus` 总线 + StringName ID（见 decisions.md 2026-08-16）
- 积木清单与参数：`docs/building_blocks.md`「机关积木（M3 第一批）」
- 玩家侧能力：`die()`（回 `spawn_point` 组标记）、`set_interactable/clear_interactable`、`enter/exit_water`、`enter/exit_ladder`；积木经 `is_in_group("player")` 判定后调用
- 演示房间 `scenes/rooms/demo_room.tscn` 由 `tools/paint_demo_room.gd` 生成：地刺坑 → 水池 → 按钮开门拿宝石 → 梯子开宝箱
