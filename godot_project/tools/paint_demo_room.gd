extends SceneTree
## 生成 M3 演示房间：room_base 模板 + 正式瓦片地形 + 全部机关积木串联。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless --script tools/paint_demo_room.gd
## 布局：出生 → 地刺坑(跳) → 水池(减速) → 按钮开门拿宝石 → 梯子上平台开宝箱(灯)

const FLOOR_TOP := 63 # 地面顶行（格）
const SRC_DIRT := 1 # TileSet source：泥土苔藓分区

var _fill := Vector2i(0, 2) # 纯泥土 fill_01
var _edge_top := Vector2i(0, 0) # 苔藓上边（地表）
var _crystal := Vector2i(0, 0) # 装饰分区：水晶簇（source 3）
var _moss_tuft := Vector2i(3, 1) # 装饰分区：苔藓丛

var _room: Node2D
var _terrain: TileMapLayer
var _decor: TileMapLayer


func _initialize() -> void:
	_room = (load("res://scenes/templates/room_base.tscn") as PackedScene).instantiate() as Node2D
	_room.scene_file_path = "" # 打包为新场景而非模板实例引用
	root.add_child(_room)
	_terrain = _room.get_node("TileMapTerrain") as TileMapLayer
	_decor = _room.get_node("TileMapDecor") as TileMapLayer

	_paint_terrain()
	_paint_decor()
	_place_mechanisms()
	_place_player()
	_save()


func _paint_terrain() -> void:
	# 地面：默认顶行苔藓边 + 下方三行填充；坑洞区域单独处理
	for x in range(0, 120):
		if x >= 12 and x <= 13: # 地刺坑：2 格宽（3格/秒×0.65s滞空≈2格跳距，3格跳不过）
			_terrain.set_cell(Vector2i(x, 65), 1, _edge_top)
			_terrain.set_cell(Vector2i(x, 66), 1, _fill)
		elif x >= 18 and x <= 24: # 水池：只留底行
			_terrain.set_cell(Vector2i(x, 66), 1, _fill)
		else:
			_terrain.set_cell(Vector2i(x, FLOOR_TOP), 1, _edge_top)
			for y in range(FLOOR_TOP + 1, 67):
				_terrain.set_cell(Vector2i(x, y), 1, _fill)
	# 左右墙壁（只补空缺，不覆盖已有地面）
	for y in range(50, 67):
		if _terrain.get_cell_source_id(Vector2i(0, y)) == -1:
			_terrain.set_cell(Vector2i(0, y), 1, _fill)
		if _terrain.get_cell_source_id(Vector2i(119, y)) == -1:
			_terrain.set_cell(Vector2i(119, y), 1, _fill)
	# 门墙：x=32，门洞下方三格留空（门占据），上方封死
	for y in range(55, 60):
		_terrain.set_cell(Vector2i(32, y), 1, _fill)
	# 门墙 2：x=74（光敏水晶门）
	for y in range(55, 60):
		_terrain.set_cell(Vector2i(74, y), 1, _fill)
	# 高台：x 46..56，行 57（梯子顶端平台）
	for x in range(46, 57):
		_terrain.set_cell(Vector2i(x, 57), 1, _edge_top)


func _paint_decor() -> void:
	_decor.set_cell(Vector2i(8, 62), 3, _crystal)
	_decor.set_cell(Vector2i(40, 62), 3, _moss_tuft)
	_decor.set_cell(Vector2i(50, 56), 3, _crystal)


func _place_mechanisms() -> void:
	var mech := _room.get_node("Mechanisms")
	var ground_y := FLOOR_TOP * 16.0

	for x in [12, 13]: # 地刺坑底（坑深 2 格，刺贴坑底）
		_add_mech(mech, "res://scenes/interactables/spikes.tscn", Vector2(x * 16 + 8, 65 * 16 - 8))

	# 水体：水池区域 7×3 格
	var water := _add_mech(mech, "res://scenes/interactables/water.tscn", Vector2(18 * 16, 66 * 16 - 48))
	water.set("size", Vector2i(7 * 16, 48))

	# 按钮 → 石门 → 门后宝石
	var button := _add_mech(mech, "res://scenes/interactables/lion_button.tscn", Vector2(28 * 16, ground_y - 8))
	button.set("target_id", &"demo_door")
	var door := _add_mech(mech, "res://scenes/interactables/stone_door.tscn", Vector2(32 * 16 + 8, ground_y - 24))
	door.set("listen_id", &"demo_door")
	var gem := _add_mech(mech, "res://scenes/interactables/pickup.tscn", Vector2(35 * 16, ground_y - 8))
	gem.set("item", &"gem_jade")

	# 梯子 → 高台宝箱（灯）
	var ladder := _add_mech(mech, "res://scenes/interactables/ladder.tscn", Vector2(45 * 16, ground_y))
	ladder.set("height", 7 * 16)
	var chest := _add_mech(mech, "res://scenes/interactables/chest.tscn", Vector2(52 * 16, 57 * 16 - 16))
	chest.set("item", &"lamp")

	# 光敏水晶 → 石门 2 → 门后琥珀（需先拿灯）
	var crystal := _add_mech(mech, "res://scenes/interactables/light_crystal.tscn", Vector2(66 * 16, ground_y - 8))
	crystal.set("target_id", &"demo_door_2")
	var door2 := _add_mech(mech, "res://scenes/interactables/stone_door.tscn", Vector2(74 * 16 + 8, ground_y - 24))
	door2.set("listen_id", &"demo_door_2")
	var gem2 := _add_mech(mech, "res://scenes/interactables/pickup.tscn", Vector2(78 * 16, ground_y - 8))
	gem2.set("item", &"gem_amber")


func _add_mech(parent: Node, scene_path: String, pos: Vector2) -> Node2D:
	var node := (load(scene_path) as PackedScene).instantiate() as Node2D
	node.position = pos
	parent.add_child(node)
	node.owner = _room
	return node


func _place_player() -> void:
	var spawn := _room.get_node("SpawnPoint") as Marker2D
	spawn.position = Vector2(80, FLOOR_TOP * 16 - 12)
	var player := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as CharacterBody2D
	player.position = spawn.position
	_room.get_node("Characters").add_child(player)
	player.owner = _room


func _save() -> void:
	var packed := PackedScene.new()
	if packed.pack(_room) != OK:
		printerr("pack failed")
		quit(1)
		return
	if ResourceSaver.save(packed, "res://scenes/rooms/demo_room.tscn") != OK:
		printerr("save failed")
		quit(1)
		return
	print("demo room saved: res://scenes/rooms/demo_room.tscn")
	quit(0)
