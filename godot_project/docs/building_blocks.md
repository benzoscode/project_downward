# 机关积木搭建手册

> 面向策划：每个积木是 `scenes/interactables/` 下的独立场景，拖入房间即可用。
> 通用规则：可调参数都在 Inspector（@export）；机关间关联用 `door_id` 等字符串 ID，不拖节点引用。

（M6 里程碑交付积木后逐个补充：用途、参数表、连线方式、截图）

## 角色积木（M5）

### mouse.tscn 老鼠（scenes/characters/）

- **操控**：Q 召唤/收回（需召唤哨），R 切换操控（玩家静止、相机切换、切回老鼠停留原地）
- **参数**：`input_delay`（秒）——第 9 房间 0.8s 延迟机制，默认 0
- **注意**：人鼠碰撞层分离（玩家层2/老鼠层3），互不推挤；地刺对老鼠致死并进 5s 冷却

### pressure_plate.tscn 压力板

- **用途**：踩下触发 `target_id`，离开解除。
- **参数**：`mouse_only`（true=小型仅老鼠 / false=大型人鼠皆可）。

## 机关积木（M6 第二批）

### alternating_platform.tscn 交替平台

- **用途**：A/B 两组按周期交替显隐（半透明+撤碰撞），全房间时间同步。
- **参数**：`period`（秒，每组各亮一半）；`group_b`（false=A 先亮）。

### lever_platform.tscn 摇杆平台

- **用途**：玩家在摇杆旁**按住 E**，平台沿 `move_offset` 移动；松开后在终点停留 `dwell_time` 再复位。编辑器内虚线显示路径。
- **参数**：`move_offset`（px）；`move_speed`（px/秒）；`dwell_time`（默认 0.5s，难度调节项）。

### dual_button_door.tscn 双按钮门

- **用途**：`listen_ids` **全部**触发才开门；任一解除后延迟 `close_delay` 秒关闭（琥珀色门面区分）。
- **参数**：`listen_ids`（数组）；`close_delay`（默认 2s）。

### trigger_relay.tscn 滞后组件

- **用途**：`input_id` 触发后延迟 `delay` 秒才触发 `output_id`（如石桥延迟升起）；解除立即传递。纯逻辑无视觉。

### grass_cover.tscn 草丛光透

- **用途**：灯光照到变透明，显露隐藏通道；纯视觉无碰撞（秘密通道本来就能走）。

### color_button.tscn + sequence_controller.tscn 水滴顺序机关

- **用途**：彩按钮按 `expected` 顺序按下 → 广播 `target_id`；按错进度清零。
- **连线**：按钮设 `sequence_id` + `color_id`；控制器设同名 `sequence_id`、`expected`（颜色数组）、`target_id`。

### fake_platform.tscn 虚空平台

- **用途**：看着是平台、踩上直接穿过（无碰撞），第 9 房间幻觉主题教学件。

### 玩家致幻参数

- `player.input_delay`（秒）：第 9 房间输入延迟。**决策记录**：渲染延迟方案风险过高，按里程碑预案降级为输入延迟。

## 角色积木（M7）

### boss.tscn 地底猎食者（scenes/characters/）

- **用途**：光敏大型生物，无血条不可击败，关系是"规避与利用"（策划案 §二(四)）。拖入房间即巡逻。
- **五状态**：巡逻（暗蓝灰）→ 警戒（黄，光源 >8 格）→ 追击（红，≤8 格/环境光暴露）→ 搜索（橙，目标消失后 10s）→ 回巡逻；警戒/追击/搜索中老鼠 ≤6 格 → 分心（紫，优先追老鼠）。接触扑杀只在追击（玩家）/分心（老鼠）状态生效。
- **参数**：
  - 感知：`chase_range_tiles`（8）、`alert_range_tiles`（12，警戒上限）、`distract_range_tiles`（6）
  - 速度：`patrol/alert/chase_speed_tiles`（1.5 / 2.5 / 4.5 格/秒，追击必须快于玩家 3）
  - 巡逻：`patrol_route`（可选 Path2D，沿路径点往返）、`patrol_half_extent_tiles`（无路径时出生点两侧往返半幅，默认 6 格）
  - 搜索：`search_duration`（10s）、`search_wander_tiles`（徘徊半幅 2 格）；`jump_height_tiles`（绕障跳高 2 格）
- **编辑器辅助**：选中即显示三个感知圈（红=追击/黄=警戒/紫=分心）与巡逻路径。
- **注意**：Boss 只与地形碰撞（层 4/mask 1），不推挤玩家老鼠；追击是直线+跳跃绕障，不会寻路——高台/复杂路线是玩家的生路（策划案 §房间12 设计）。

### ambient_light.tscn 环境光源

- **用途**：熔岩裂缝/荧光苔藓等恒定光源。照亮半径内的玩家即使关灯也会被 Boss 感知（"暴露在环境光"）。
- **参数**：`radius_tiles`（格，默认 4，同时决定光晕视觉大小与判定范围）。
- **连线**：无需连线，注册到 LightSystem 自动生效；地形遮挡同样生效（隔墙不暴露）。

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
- **参数**：`listen_id`；`start_open`（常开门，信号反转）；`tween_duration`；`tint`（门面调色，用于区分开启方式，如水晶门青色）
- **尺寸**：32×48（2×3 格），origin 在门中心。

### pickup.tscn 道具拾取物

- **用途**：触碰即获得，写入 GameState。
- **参数**：`item` = `lamp`/`boots`/`whistle`/`gem_jade`/`gem_amber`/`gem_violet`，图标自动匹配。

### chest.tscn 宝箱

- **用途**：E 开启发放道具（一次性），开盖换图。
- **参数**：`item`（同上）。

### light_crystal.tscn 光敏水晶（M2）
- **用途**：被玩家锥形灯持续照射 2 秒激活，广播 `target_id`；激活后常亮并发光。
- **参数**：`target_id`（联动 ID）；`charge_time`（默认 2.0s，策划案 §二(二)1）。
- **判定**：经 LightSystem（射程 6 格内 + 锥角内 + 射线无遮挡），石柱/墙体挡光有效。
- **视觉**：随照射进度渐亮，激活变亮青 + 发光。

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
