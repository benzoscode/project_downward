extends SceneTree
## 生成 M7 Boss 试验场：巡逻路径 + 环境光区 + 高台，演示五状态切换与老鼠诱敌。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless --script tools/paint_boss_lab.gd

const TRACK_W := 60 # 格
const SCREEN_H := 17
const FLOOR_TOP := 13
const SRC_DIRT := 1

var _fill := Vector2i(0, 2)
var _edge_top := Vector2i(0, 0)

var _lab: Node2D
var _terrain: TileMapLayer
var _characters: Node2D


func _initialize() -> void:
	_lab = Node2D.new()
	_lab.name = "BossLab"
	root.add_child(_lab)

	# 运行时暗环境（同房间模板 game_darkness）
	var dark := CanvasModulate.new()
	dark.name = "CanvasModulate"
	dark.color = Color(0.05, 0.05, 0.05, 1)
	_lab.add_child(dark)
	dark.owner = _lab

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

	var mech := Node2D.new()
	mech.name = "Mechanisms"
	_lab.add_child(mech)
	mech.owner = _lab

	_characters = Node2D.new()
	_characters.name = "Characters"
	_lab.add_child(_characters)
	_characters.owner = _lab

	_paint_terrain()

	var gy := FLOOR_TOP * 16.0

	# 起步给灯与哨（试验场直接拾取）
	var lamp := _add_to(mech, "res://scenes/interactables/pickup.tscn", Vector2(4 * 16, gy - 8))
	lamp.set("item", &"lamp")
	var whistle := _add_to(mech, "res://scenes/interactables/pickup.tscn", Vector2(5 * 16, gy - 8))
	whistle.set("item", &"whistle")

	# 环境光区（x 44 附近）：演示"关灯但暴露于环境光仍被追击"
	_add_to(mech, "res://scenes/interactables/ambient_light.tscn", Vector2(44 * 16, gy - 32))

	# 出生点
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.add_to_group(&"spawn_point")
	spawn.position = Vector2(3 * 16, gy - 12)
	_lab.add_child(spawn)
	spawn.owner = _lab

	var player := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as CharacterBody2D
	player.name = "Player"
	player.position = Vector2(3 * 16, gy - 12)
	_characters.add_child(player)
	player.owner = _lab

	# Boss：中段三点巡逻路径（x 20/30/40），经过 2 格高台演示绕障跳跃
	var route := Path2D.new()
	route.name = "PatrolRoute"
	var curve := Curve2D.new()
	curve.add_point(Vector2(20 * 16, gy - 48))
	curve.add_point(Vector2(30 * 16, gy - 48))
	curve.add_point(Vector2(40 * 16, gy - 48))
	route.curve = curve
	_lab.add_child(route)
	route.owner = _lab

	var boss := (load("res://scenes/characters/boss.tscn") as PackedScene).instantiate() as Boss
	boss.name = "Boss"
	boss.position = Vector2(20 * 16, gy - 48)
	boss.patrol_route = route
	_characters.add_child(boss)
	boss.owner = _lab

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
	if packed.pack(_lab) != OK or ResourceSaver.save(packed, "res://scenes/test/boss_lab.tscn") != OK:
		printerr("save failed")
		quit(1)
		return
	print("boss lab saved")
	quit(0)


func _paint_terrain() -> void:
	for x in range(0, TRACK_W):
		_terrain.set_cell(Vector2i(x, FLOOR_TOP), SRC_DIRT, _edge_top)
		for y in range(FLOOR_TOP + 1, SCREEN_H):
			_terrain.set_cell(Vector2i(x, y), SRC_DIRT, _fill)
	for y in range(0, SCREEN_H): # 两端墙
		_terrain.set_cell(Vector2i(0, y), SRC_DIRT, _fill)
		_terrain.set_cell(Vector2i(TRACK_W - 1, y), SRC_DIRT, _fill)
	# 2 格高障碍（x 25）：Boss 追击中演示跳跃绕障
	for y in range(11, FLOOR_TOP):
		_terrain.set_cell(Vector2i(25, y), SRC_DIRT, _fill)
	# 5 格高台（x 33..35，行 8..12）：玩家二段跳躲避点（需靴，试验场无靴则仅作掩体观察）
	for x in range(33, 36):
		for y in range(8, FLOOR_TOP):
			_terrain.set_cell(Vector2i(x, y), SRC_DIRT, _fill)


func _add_to(parent: Node, scene_path: String, pos: Vector2) -> Node2D:
	var node := (load(scene_path) as PackedScene).instantiate() as Node2D
	node.position = pos
	parent.add_child(node)
	node.owner = _lab
	return node
