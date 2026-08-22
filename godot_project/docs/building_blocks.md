# 机关积木搭建手册

> 面向策划：每个积木是 `scenes/interactables/` 下的独立场景，拖入房间即可用。
> 通用规则：可调参数都在 Inspector（@export）；机关间关联用 `door_id` 等字符串 ID，不拖节点引用。
> 📖 图文版入门指南：**[关卡搭建指南.html](./关卡搭建指南.html)**（浏览器打开）。

（M6 里程碑交付积木后逐个补充：用途、参数表、连线方式、截图）

## 角色积木（M5）

### mouse.tscn 老鼠（scenes/characters/）

- **操控**：Q 召唤/收回（需召唤哨），R 切换操控（玩家静止、相机切换、切回老鼠停留原地）
- **参数**：`input_delay`（秒）——第 9 房间 0.8s 延迟机制，默认 0
- **注意**：人鼠碰撞层分离（玩家层2/老鼠层3），互不推挤；地刺对老鼠致死并进 5s 冷却

### pressure_plate.tscn 压力板

- **用途**：踩下触发 `target_id`，离开解除。
- **参数**：`mouse_only`（true=小型仅老鼠 / false=大型人鼠皆可）。

## 机关积木（第三批，2026-08-18）

### one_way_platform.tscn 单向平台

- **用途**：下方/侧面自由穿越，只能站顶面；**没有下落键**——按 S 也不会掉（与常见单向平台不同，用户需求）。
- **参数**：`width_tiles`（宽度格数，@tool 拖动即所见）。

### orb_launcher.tscn 光球发射器 + light_orb.tscn 光球

- **用途**：收到触发即沿朝向射出发光球（初速沿方向，之后受衰减重力**缓降**，到时消散）；冷却 1s 可连发。典型搭配：狮子头按钮开 `momentary` 点动模式 → `target_id` 指发射器 `listen_id`。
- **参数**：`listen_id`；`launch_speed`（默认 120px/s）；`cooldown`（1s）；`orb_lifetime`（10s）；`orb_tint`（光球颜色）。
- **方向**：旋转发射器节点即调发射方向（编辑器内 +X 箭头可视化）。
- **总线补充**：`MechanismBus.pulse(id)` 脉冲触发——只发信号不存状态，事件型联动（发射/连按）专用；`trigger()` 仍是状态型（重复触发同 id 不会重复发信号）。

### lion_button 增配

- `momentary`（点动）：每按一次发一次脉冲，不做开/关切换。

## 机关积木（M6 第二批）
### alternating_platform.tscn 交替平台

- **用途**：A/B 两组按周期交替显隐（半透明+撤碰撞），全房间时间同步。
- **参数**：`period`（秒，每组各亮一半）；`group_b`（false=A 先亮）。

### lever_platform.tscn 摇杆平台

- **用途**：玩家在摇杆旁**按住 E**，平台沿 `move_offset` 移动；松开后在终点停留 `dwell_time` 再复位。编辑器内虚线显示路径 + 终点幽灵框。
- **参数**：`platform_offset`（平台起点相对摇杆的偏移——**摇杆与平台可分开摆放**）；`move_offset`（px）；`move_speed`（px/秒）；`dwell_time`（默认 0.5s，难度调节项）。

### dual_button_door.tscn 双按钮门

- **用途**：`listen_ids` **全部**触发才开门；任一解除后延迟 `close_delay` 秒关闭。门面为石门素材变体 3。
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

## 机关积木（2026-08-20 新增）

### dual_plate_door.tscn 双压力板门

- **用途**：两块压力板**同时踩下**才开门；任一松开**立即关闭**（`close_delay`=0，2026-08-20 用户拍板；策划案只对双按钮门写 2s 延迟）。
- **连线**：两块 `pressure_plate.tscn` 的 `target_id` 分别设为 `plate_a`/`plate_b`（或在门上改 `listen_ids` 对齐自定义 ID）。

### lever_drawbridge.tscn 摇杆吊桥

- **用途**：摇杆旁**按住 E** 吊桥升起；停止互动吊桥立即以 `lower_speed` **缓慢下降**直至回到起始位置（无停留，区别于摇杆平台）。编辑器内虚线 + 幽灵框显示升降轨迹。
- **参数**：`bridge_offset`（吊桥起点相对摇杆偏移——**两者可分开摆放**）；`raise_offset`（升起位移，默认竖直上 3 格）；`raise_speed`（默认 48px/s）；`lower_speed`（默认 20px/s，刻意慢于升起）。

### gem_gate.tscn 三宝石门

- **用途**：门上三个宝石凹槽，玩家靠近按 E 将身上一颗宝石镶嵌到对应凹槽；翡翠/琥珀/紫金三颗**全部镶嵌**后大门上升开启。镶嵌顺序按 `socket_order`（默认翡翠→琥珀→紫金，对应策划案刻痕顺序）。镶嵌会从背包移除对应宝石。
- **参数**：`gate_id`（每门唯一的持久化 ID，socket 状态写 `<gate_id>_<宝石>`，死亡复活自动复原）；`socket_order`（Array[StringName]，jade/amber/violet）；`open_emit_id`（全开后额外广播的机关 ID，可选）；`tween_duration`。
- **文档**：策划案 §房间12 三宝石之门；全开后 `is_open()` 供脚本查询。

### breathing_light.tscn 呼吸灯

- **用途**：纯视觉发光节点，光强按正弦周期亮灭（呼吸灯），颜色可自定义。无碰撞、无交互，用于氛围/路径提示。
- **参数**：`light_color`（发光颜色）；`min_energy`/`max_energy`（暗/亮光强）；`period`（亮灭周期秒）；`pulse_scale`（是否同步缩放光斑）。

### 玩家致幻参数

- `player.input_delay`（秒）：第 9 房间输入延迟。**决策记录**：渲染延迟方案风险过高，按里程碑预案降级为输入延迟。

## 房间搭建协议（M8）

- **房间根节点**：挂 `RoomBase` 脚本（模板 `scenes/templates/room_base.tscn` 复制改名）。`player_input_delay` 配房间级致幻（第 9 房间 0.8）。**无需任何登记**——新房间丢进 `scenes/rooms/` 即可被指出口。
- **入口**：放 Marker2D 命名 `Entrance_<id>`（如 `Entrance_default`、`Entrance_corridor`）——对面房间的出口会指到这里。进入房间即自动存档（检查点=入口位置）。
- **出口**：拖 `room_exit.tscn`，Inspector 里 `target_scene` **直接选 .tscn 文件**（文件选择器），`target_entrance` 填对面入口 id（default 可省略）。编辑器里出口显示青色描边+目标文字。门控（钥匙门/石门）用实体机关挡在出口前，出口积木本身不做条件判断。回程出口需要在对门房间再配一个指回来的——双向由人控制，不强制。
- **检查点**：房间中部需要存档时拖 `checkpoint.tscn`（红旗占位），玩家触碰即存档，死亡回这里；触碰后变金色。
- **玩家**：灰盒房间不放玩家——RoomManager 自动实例化并落位；测试场景自带玩家则被收养。
- **灰盒装修规则**：room_01–12 骨架由 `tools/paint_rooms_graybox.gd` 生成（紧凑测试尺寸 40×17）；策划在其上装修（装饰层/机关/灯光），**出入口位置与能力门结构（高墙/窄缝/钥匙门）不可改动**，否则连通性断言（verify_rooms）会红。走廊/通道类过渡空间并入相邻房间，不单独做场景。

### room_exit.tscn 房间出口

- **用途**：玩家进入触发区 → 切换场景（0.4s 渐出/0.15s 黑场/0.4s 渐入），落到目标场景指定入口。
- **参数**：`target_scene`（文件选择器）、`target_entrance`。

### checkpoint.tscn 检查点

- **用途**：触碰即把检查点设为本点（当前场景+本坐标），死亡回这里；触碰后旗帜变金色。
- **参数**：无需配置。

### sign.tscn 告示牌

- **用途**：玩家靠近按 E，HUD 弹出 `text` 文字（多行支持），用于机制提示/环境叙事。实例见 room_01 光敏水晶旁。
- **参数**：`text`（告示内容）。

### key_door.tscn 钥匙门

- **用途**：持有钥匙（第 4 房间宝箱）才开启的金色门；策划案 §三(三) 第 3 房间右上角→12 房。
- **连线**：无需配置，监听 `GameState.has_key`；开门动画 0.6s 可调 `tween_duration`。

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

- **用途**：浸入减速 50% + 半透明；入水瞬间砍掉大部分下坠冲量（落水缓冲），水中缓沉（坠落限速 2.5 格/秒）；编辑器内直接拖 `size`。
- **参数**：`size`（px，origin 左上角）；玩家侧 `water_speed_multiplier`/`water_gravity_multiplier`/`water_entry_damp`/`water_max_fall_tiles` 可调。

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

### source 5：石砖（全部带碰撞+遮光，第三批）

- (0)砖体 (1)砖顶 (2-4)草顶砖 01~03 (5-7)裂纹砖 01~03

### source 6：草丛装饰（无碰撞，画到 TileMapDecor）

- (0-6)草丛 01~07

### source 7：水面静态瓦片（无碰撞）

- (0)水面 01。水的物理（减速/浮力）仍由 `water.tscn` 积木承担，瓦片只管视觉。

### source 8-11：水体动画瓦片（无碰撞，引擎图集动画，刷上即播）

| source | 内容 | 帧数 | 速度 |
|---|---|---|---|
| 8 | 平静水体 | 9 帧 | 6fps |
| 9 | 平静水体·长循环 | 18 帧 | 6fps |
| 10 | 波浪水体 01 | 16 帧 | 6fps |
| 11 | 波浪水体 02 | 16 帧 | 6fps |

> 帧在图集同一行横向连续；DEFAULT 模式全场同相位。速度/相位模式可在编辑器 TileSet 面板直接调。
> 序列帧内的重复帧是动画节奏设计，重新导入时不得去重（import_tiles_batch3.ps1）。
