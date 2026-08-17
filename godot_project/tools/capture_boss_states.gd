extends Node
## M7 五状态演示截图：驱动 Boss 经历 巡逻/警戒/追击/分心/搜索 五态，各存一张 PNG。
## 输出到 tools/out/boss_state_<state>.png（不入库），供人类审阅。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> res://scenes/test/verify_host.tscn --position -2000,100 -- res://tools/capture_boss_states.gd

const SURFACE_Y := 384.0
const SPAWN := Vector2(160, SURFACE_Y - 10.0)
const BOSS_Y := SURFACE_Y - 48.0
const OUT_DIR := "res://tools/out/"

var _player: CharacterBody2D
var _lamp: Node2D
var _boss: Boss
var _step: int = 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1600, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(800, SURFACE_Y + 16.0)
	add_child(floor_body)

	var spawn := Marker2D.new()
	spawn.add_to_group(&"spawn_point")
	spawn.position = SPAWN
	add_child(spawn)

	_player = (load("res://scenes/characters/player.tscn") as PackedScene).instantiate()
	_player.position = SPAWN
	add_child(_player)
	_lamp = _player.get_node("Lamp")
	GameState.has_lamp = true

	_boss = (load("res://scenes/characters/boss.tscn") as PackedScene).instantiate() as Boss
	_boss.patrol_half_extent_tiles = 2.0
	_boss.position = Vector2(SPAWN.x + 96.0, BOSS_Y)
	add_child(_boss)

	# 截图相机：跟随 Boss 所在区域（验证场地坐标超出默认 480×270 视口，必须有相机）
	var camera := Camera2D.new()
	camera.position = Vector2(SPAWN.x + 120.0, SURFACE_Y - 80.0)
	camera.enabled = true
	add_child(camera)
	_run()


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


func _shot(tag: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	var path := OUT_DIR + "boss_state_" + tag + ".png"
	if img.save_png(path) == OK:
		print("screenshot saved: ", path)
	else:
		printerr("save failed: ", path)


func _run() -> void:
	await _frames(30)
	await _shot("1_patrol")

	_lamp.call("set_lamp_on", true)
	_lamp.call("lock_aim_to", _boss.global_position)
	_boss.reset_to_patrol(Vector2(SPAWN.x + 160.0, BOSS_Y))
	await _frames(20) # 警戒（>8 格）
	await _shot("2_alert")

	_boss.reset_to_patrol(Vector2(SPAWN.x + 96.0, BOSS_Y))
	await _frames(40) # 追击（≤8 格），Boss 逼近玩家
	await _shot("3_chase")

	var mouse := (load("res://scenes/characters/mouse.tscn") as PackedScene).instantiate() as Mouse
	mouse.position = Vector2(_boss.global_position.x - 90.0, SURFACE_Y - 3.0)
	add_child(mouse)
	ControlManager.mouse = mouse
	await _frames(10) # 分心（老鼠尚未被追上）
	await _shot("4_distracted")

	if is_instance_valid(mouse):
		mouse.global_position = Vector2(_boss.global_position.x - 400.0, SURFACE_Y - 3.0)
	else:
		# 已被捕获则补一只远处老鼠，仅作画面参照
		mouse = (load("res://scenes/characters/mouse.tscn") as PackedScene).instantiate() as Mouse
		mouse.position = Vector2(_boss.global_position.x - 400.0, SURFACE_Y - 3.0)
		add_child(mouse)
		ControlManager.mouse = mouse
	_lamp.call("set_lamp_on", false)
	await _frames(20) # 搜索
	await _shot("5_search")

	print("CAPTURE DONE")
	get_tree().quit(0)
