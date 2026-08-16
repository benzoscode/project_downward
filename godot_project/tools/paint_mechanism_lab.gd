extends SceneTree
## 生成 M4-M6 综合试验场：长跑道串联二段跳/老鼠/压力板/M6 全部积木。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless --script tools/paint_mechanism_lab.gd

const TRACK_W := 200 # 格
const SCREEN_H := 17
const FLOOR_TOP := 13
const SRC_DIRT := 1

var _fill := Vector2i(0, 2)
var _edge_top := Vector2i(0, 0)

var _lab: Node2D
var _terrain: TileMapLayer
var _mech: Node2D


func _initialize() -> void:
	_lab = Node2D.new()
	_lab.name = "MechanismLab"
	root.add_child(_lab)

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.10, 0.12, 0.18, 1)
	bg.size = Vector2(TRACK_W * 16, SCREEN_H * 16)
	_lab.add_child(bg)
	bg.owner = _lab

	_terrain = TileMapLayer.new()
	_terrain.name = "TileMapTerrain"
	_terrain.tile_set = load("res://assets/tiles/tileset_cave.tres") as TileSet
	_lab.add_child(_terrain)
	_terrain.owner = _lab

	_mech = Node2D.new()
	_mech.name = "Mechanisms"
	_lab.add_child(_mech)
	_mech.owner = _lab

	_paint_terrain()
	_place_all()

	var player := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as CharacterBody2D
	player.name = "Player"
	player.position = Vector2(3 * 16, FLOOR_TOP * 16 - 12)
	_lab.add_child(player)
	player.owner = _lab

	var camera := Camera2D.new()
	camera.name = "RoomCamera"
	camera.position = player.position
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = TRACK_W * 16
	camera.limit_bottom = SCREEN_H * 16
	camera.enabled = true
	_lab.add_child(camera)
	camera.owner = _lab
	var host := Node.new()
	host.name = "PhantomCameraHost"
	host.set_script(load("res://addons/phantom_camera/scripts/phantom_camera_host/phantom_camera_host.gd"))
	camera.add_child(host)
	host.owner = _lab

	var packed := PackedScene.new()
	if packed.pack(_lab) != OK or ResourceSaver.save(packed, "res://scenes/test/mechanism_lab.tscn") != OK:
		printerr("save failed")
		quit(1)
		return
	print("mechanism lab saved")
	quit(0)


func _fill_ground(from_x: int, to_x: int) -> void:
	for x in range(from_x, to_x + 1):
		_terrain.set_cell(Vector2i(x, FLOOR_TOP), SRC_DIRT, _edge_top)
		for y in range(FLOOR_TOP + 1, SCREEN_H):
			_terrain.set_cell(Vector2i(x, y), SRC_DIRT, _fill)


func _wall(x: int, top_row: int) -> void:
	# 只封门洞上方：门占下 3 格（行 10..12），墙面不得压进门洞
	for y in range(top_row, 10):
		_terrain.set_cell(Vector2i(x, y), SRC_DIRT, _fill)


func _paint_terrain() -> void:
	# 地面：交替平台坑（37..46）与虚空平台坑（92..97）只留底行
	for x in range(0, TRACK_W):
		if (x >= 37 and x <= 46) or (x >= 92 and x <= 97):
			_terrain.set_cell(Vector2i(x, SCREEN_H - 1), SRC_DIRT, _fill)
		else:
			_fill_ground(x, x)
	for y in range(0, SCREEN_H): # 两端墙
		_terrain.set_cell(Vector2i(0, y), SRC_DIRT, _fill)
		_terrain.set_cell(Vector2i(TRACK_W - 1, y), SRC_DIRT, _fill)
	# 5 格高台（二段跳）：x 12..14，行 8..12
	for x in range(12, 15):
		for y in range(8, FLOOR_TOP):
			_terrain.set_cell(Vector2i(x, y), SRC_DIRT, _fill)
	# 窄缝走廊：x 20..24 只留 1 格高（行 12 空，行 11 起封）
	for x in range(20, 25):
		for y in range(9, 12):
			_terrain.set_cell(Vector2i(x, y), SRC_DIRT, _fill)
	# 各门墙（下 3 格留空给门）
	for wx in [31, 65, 73, 88]:
		_wall(wx, 5)
	# 摇杆平台的目标高台：x 56..60，行 9
	for x in range(56, 61):
		_terrain.set_cell(Vector2i(x, 9), SRC_DIRT, _edge_top)


func _add(scene_path: String, pos: Vector2) -> Node2D:
	var node := (load(scene_path) as PackedScene).instantiate() as Node2D
	node.position = pos
	_mech.add_child(node)
	node.owner = _lab
	return node


func _place_all() -> void:
	var gy := FLOOR_TOP * 16.0

	# 起步三道具：靴/哨/灯（试验场直接给全）
	var boots := _add("res://scenes/interactables/pickup.tscn", Vector2(4 * 16, gy - 8))
	boots.set("item", &"boots")
	var whistle := _add("res://scenes/interactables/pickup.tscn", Vector2(5 * 16, gy - 8))
	whistle.set("item", &"whistle")
	var lamp := _add("res://scenes/interactables/pickup.tscn", Vector2(6 * 16, gy - 8))
	lamp.set("item", &"lamp")

	# 高台顶放翡翠（二段跳奖励）
	var gem1 := _add("res://scenes/interactables/pickup.tscn", Vector2(13 * 16, 8 * 16 - 8))
	gem1.set("item", &"gem_jade")

	# 小压力板（仅老鼠）→ 门1（窄缝后）→ 门后琥珀
	var plate := _add("res://scenes/interactables/pressure_plate.tscn", Vector2(28 * 16, gy - 2))
	plate.set("target_id", &"lab_door_1")
	plate.set("mouse_only", true)
	var door1 := _add("res://scenes/interactables/stone_door.tscn", Vector2(31 * 16 + 8, gy - 24))
	door1.set("listen_id", &"lab_door_1")
	var gem2 := _add("res://scenes/interactables/pickup.tscn", Vector2(34 * 16, gy - 8))
	gem2.set("item", &"gem_amber")

	# 交替平台坑：A/B/A 三座（周期 1.5s，策划案房间 8 定值）
	for i in range(3):
		var p := _add("res://scenes/interactables/alternating_platform.tscn", Vector2((38 + i * 3) * 16, gy - 32))
		p.set("period", 1.5)
		p.set("group_b", i == 1)

	# 摇杆平台：摇杆在 x50 地面，平台通往高台
	var lever := _add("res://scenes/interactables/lever_platform.tscn", Vector2(50 * 16, gy - 8))
	lever.set("move_offset", Vector2(56, -48))
	lever.set("move_speed", 48.0)

	# 双按钮门：x60 + x62 → 门 x65
	var b1 := _add("res://scenes/interactables/lion_button.tscn", Vector2(60 * 16, gy - 8))
	b1.set("target_id", &"dual_a")
	var b2 := _add("res://scenes/interactables/lion_button.tscn", Vector2(62 * 16, gy - 8))
	b2.set("target_id", &"dual_b")
	var dual := _add("res://scenes/interactables/dual_button_door.tscn", Vector2(65 * 16 + 8, gy - 24))
	dual.set("listen_ids", [&"dual_a", &"dual_b"] as Array[StringName])

	# 滞后组件：按钮 x70 → 2s 后 → 门 x73
	var b3 := _add("res://scenes/interactables/lion_button.tscn", Vector2(70 * 16, gy - 8))
	b3.set("target_id", &"relay_in")
	var relay := _add("res://scenes/interactables/trigger_relay.tscn", Vector2(70 * 16, gy))
	relay.set("input_id", &"relay_in")
	relay.set("output_id", &"relay_out")
	relay.set("delay", 2.0)
	var door3 := _add("res://scenes/interactables/stone_door.tscn", Vector2(73 * 16 + 8, gy - 24))
	door3.set("listen_id", &"relay_out")
	door3.set("tint", Color(0.95, 0.75, 0.3))

	# 草丛光透：盖住紫金壁龛（灯下显形）
	var gem3 := _add("res://scenes/interactables/pickup.tscn", Vector2(78 * 16, gy - 8))
	gem3.set("item", &"gem_violet")
	_add("res://scenes/interactables/grass_cover.tscn", Vector2(78 * 16, gy - 8))

	# 顺序机关：红→绿 → 门 x88
	var ctrl := _add("res://scenes/interactables/sequence_controller.tscn", Vector2(84 * 16, gy))
	ctrl.set("sequence_id", &"lab_seq")
	ctrl.set("expected", [&"red", &"green"] as Array[StringName])
	ctrl.set("target_id", &"seq_door")
	var br := _add("res://scenes/interactables/color_button.tscn", Vector2(83 * 16, gy - 8))
	br.set("color_id", &"red")
	br.set("sequence_id", &"lab_seq")
	var bg2 := _add("res://scenes/interactables/color_button.tscn", Vector2(85 * 16, gy - 8))
	bg2.set("color_id", &"green")
	bg2.set("sequence_id", &"lab_seq")
	var door4 := _add("res://scenes/interactables/stone_door.tscn", Vector2(88 * 16 + 8, gy - 24))
	door4.set("listen_id", &"seq_door")
	door4.set("tint", Color(0.7, 0.6, 1.0))

	# 虚空平台坑：真（96）假（94）平台并排
	_add("res://scenes/interactables/fake_platform.tscn", Vector2(94 * 16, gy - 48))
	for x in range(96, 98):
		_terrain.set_cell(Vector2i(x, 10), SRC_DIRT, _edge_top)
