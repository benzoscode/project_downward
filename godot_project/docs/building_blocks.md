# 机关积木搭建手册

> 面向策划：每个积木是 `scenes/interactables/` 下的独立场景，拖入房间即可用。
> 通用规则：可调参数都在 Inspector（@export）；机关间关联用 `door_id` 等字符串 ID，不拖节点引用。

（M6 里程碑交付积木后逐个补充：用途、参数表、连线方式、截图）

## 机关积木（M3 第一批）

> 联动规则：触发源设 `target_id`、接收方设 `listen_id`，同名即联动；可一对多。
> 机关状态存在 MechanismBus 单例里，玩家死亡重生后机关保持原状态（策划案 §一）。

### spikes.tscn 地刺

- **用途**：触碰即死，玩家回房间出生点。
- **放置**： origin 在瓦片中心，贴地放（刺高半格）。
- **参数**：无。

### lion_button.tscn 狮子头按钮

- **用途**：玩家靠近按 E 触发，广播 `target_id`。
- **参数**：`target_id`（联动 ID）；`one_shot`（true=一次性，false=开关切换）。
- **交互范围**：28×20，可跨 1 格多触发。

### stone_door.tscn 石门

- **用途**：监听 `listen_id` 开/关（向上滑入动画 0.4s）。
- **参数**：`listen_id`；`start_open`（常开门，信号反转）；`tween_duration`。
- **尺寸**：32×48（2×3 格），origin 在门中心。

### pickup.tscn 道具拾取物

- **用途**：触碰即获得，写入 GameState。
- **参数**：`item` = `lamp`/`boots`/`whistle`/`gem_jade`/`gem_amber`/`gem_violet`，图标自动匹配。

### chest.tscn 宝箱

- **用途**：E 开启发放道具（一次性），开盖换图。
- **参数**：`item`（同上）。

### water.tscn 水体

- **用途**：浸入减速 50% + 半透明；编辑器内直接拖 `size`。
- **参数**：`size`（px，origin 左上角）；玩家侧 `water_speed_multiplier`/`water_gravity_multiplier` 可调。

### ladder.tscn 梯子

- **用途**：范围内按 W/S（move_up/down）攀爬，空格翻出（完整跳跃）。
- **参数**：`height`（px，origin 在底部，向上延伸）；搭建时顶端高出平台半格以上便于翻越。


## 模板

### room_base.tscn（房间模板）

- **用途**：所有房间的起点。复制到 `scenes/rooms/room_XX.tscn` 改名即用。
- **内置**：黑暗基底、三个 TileMapLayer 节点（TileMapTerrain 碰撞 / TileMapDecor 装饰 / TileMapMechanismMarkers 标记）、出生点、出口触发区、相机边界（1920×1080）。
- **搭建步骤**：在 TileMapTerrain 画地形 → TileMapDecor 画装饰 → 把机关拖入 Mechanisms 节点 → 调整 SpawnPoint / ExitTrigger 位置。

## TileSet 分区（tileset_cave.tres）

> 图块在编辑器 TileMap 面板顶部按 source 切换选择。坐标为图集内（列, 行），0 起。
> 布局由 `tools/build_tileset.gd` 生成，改布局必须改脚本并重跑，不要手改图集 PNG。

### source 0：占位图块（将逐步淘汰）

- (0~3, 0) 带碰撞实心/平台；(0~2, 1) 纯装饰

### source 1：泥土苔藓（全部带碰撞）

| 行 | 内容 |
|---|---|
| 行0 | (0)苔藓上边 (1)苔藓上边·石块 (2)苔藓上边·垂挂 (3)苔藓下边 (4)苔藓左边 (5)苔藓右边 |
| 行1 | (0-3)苔藓拐角 左上/右上/左下/右下；(4-7)苔藓点缀 左上/右上/左下/右下 |
| 行2 | (0-3)纯泥土 fill_01~04；(4)苔藓斑 (5-6)碎石泥土 01/02 |
| 行3 | (0-1)苔藓脉纹 01/02 (2)脉纹+水晶 (3)大水晶泥土 (4)水晶斑 |

### source 2：石质（全部带碰撞）

- (0)石墙 (1)石墙·藤蔓 (2)深色藤蔓墙 (3)深色藤蔓墙·水晶 (4-5)石板 01/02 (6)石刻面砖

### source 3：装饰 16px（无碰撞，画到 TileMapDecor）

| 行 | 内容 |
|---|---|
| 行0 | (0-1)水晶簇 (2)水晶对 (3)水晶碎片 (4)水晶碎屑 (5)单水晶 (6)垂水晶 |
| 行1 | (0)垂藤蔓 (1)平铺藤蔓 (2)灰藤蔓 (3-4)苔藓丛 01/02 |
| 行2 | (0-2)钟乳石 01~03 (3-5)石笋 01~03 |
| 行3 | (0)岩石 (1)岩土 (2)苔藓巨石 (3)石拱 |

### source 4：装饰 32×32（无碰撞）

- (0)石柱 (1)苔藓石柱
