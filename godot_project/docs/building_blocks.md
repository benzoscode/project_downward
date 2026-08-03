# 机关积木搭建手册

> 面向策划：每个积木是 `scenes/interactables/` 下的独立场景，拖入房间即可用。
> 通用规则：可调参数都在 Inspector（@export）；机关间关联用 `door_id` 等字符串 ID，不拖节点引用。

（M3/M6 里程碑交付积木后逐个补充：用途、参数表、连线方式、截图）

## 模板

### room_base.tscn（房间模板）

- **用途**：所有房间的起点。复制到 `scenes/rooms/room_XX.tscn` 改名即用。
- **内置**：黑暗基底、三层 TileMap（Terrain 碰撞 / Decor 装饰 / MechanismMarkers 标记）、出生点、出口触发区、相机边界（1920×1080）。
- **搭建步骤**：在 Terrain 层画地形 → Decor 层画装饰 → 把机关拖入 Mechanisms 节点 → 调整 SpawnPoint / ExitTrigger 位置。
