# 架构总览 — 《downward》

> 每个里程碑完成后更新本文档。当前对应里程碑：**M0 工程地基**。

## 1. 技术基础

- Godot 4.7 stable，GDScript 全静态类型
- 渲染：480×270 原生 + 整数倍缩放（viewport 拉伸 / keep / integer），Nearest 过滤，像素 snapping
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

## 4. 房间模板（room_base.tscn）节点树

```
RoomBase (Node2D)
├── CanvasModulate      # 全局黑暗基底（0.05, 0.06, 0.09）
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

TileSet：`assets/placeholder/tileset_cave.tres`，图集 4×2 块 16×16，上行 4 块带碰撞、下行 3 块纯装饰。

## 5. 输入映射

`move_left/right`（A/D/方向键）、`jump`（空格）、`toggle_lamp`（F）、`whistle`（Q）、`switch_control`（R）、`interact`（E）

## 6. 开发工具

| 工具 | 用途 |
|---|---|
| `tools/generate_placeholders.ps1` | 生成全部占位素材（尺寸规范见 AGENTS.md §7） |
| `tools/verify_smoke.ps1` | headless 导入检查 + 场景冒烟，CI 式退出码 |
| `tools/capture.gd` | 截图：加载场景跑 N 帧存 PNG（输出到 `tools/out/`，不入库） |

（状态机、光照系统、机关协议、Boss AI 等随里程碑补充）
