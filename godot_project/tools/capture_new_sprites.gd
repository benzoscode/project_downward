extends Node
## 2026-08-20 新素材截图：奔跑(有灯) / 上爬 / 下爬 / 鼠鼠待机。
## 输出 tools/out/sprite2_*.png。用法（godot_project/ 下，非 headless）：
##   & <godot_console.exe> res://scenes/test/verify_host.tscn --position -2000,100 -- res://tools/capture_new_sprites.gd

var _player: CharacterBody2D
var _lamp: Node2D


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://tools/out/")
	var dark := CanvasModulate.new()
	dark.color = Color(0.08, 0.08, 0.1, 1)
	add_child(dark)
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(480, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(240, 240)
	add_child(floor_body)

	_player = (load("res://scenes/characters/player.tscn") as PackedScene).instantiate()
	_player.position = Vector2(240, 220)
	add_child(_player)
	_lamp = _player.get_node("Lamp")
	GameState.has_lamp = true

	var camera := Camera2D.new()
	camera.position = Vector2(240, 200)
	camera.zoom = Vector2(2, 2)
	camera.enabled = true
	add_child(camera)
	_run()


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


func _shot(tag: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "res://tools/out/sprite2_" + tag + ".png"
	if get_tree().root.get_texture().get_image().save_png(path) == OK:
		print("screenshot saved: ", path)
	print(tag, " anim=", _player.get_node("AnimatedSprite2D").animation,
		" frame=", _player.get_node("AnimatedSprite2D").frame)


func _run() -> void:
	await _frames(30)
	# 奔跑（有灯）：直接给水平速度，关闭减速防刹停
	_lamp.call("set_lamp_on", true)
	_lamp.call("lock_aim_to", _player.global_position + Vector2(80, -10))
	_player.set("deceleration", 0.0)
	_player.set("control_active", false)
	_player.velocity.x = 48.0
	await _frames(9)
	await _shot("run_lamp")
	_player.velocity.x = 0.0
	await _frames(5)
	# 上爬：模拟进入梯子并按住上
	_player.set("control_active", true)
	_player.call("enter_ladder", 240.0)
	Input.action_press(&"move_up")
	await _frames(8)
	await _shot("climb_up")
	Input.action_release(&"move_up")
	await _frames(2)
	# 下爬：按住下，趁未落地截图
	Input.action_press(&"move_down")
	await _frames(5)
	await _shot("climb_down")
	Input.action_release(&"move_down")
	# 鼠鼠待机：完全替换后的正式素材
	var mouse := (load("res://scenes/characters/mouse.tscn") as PackedScene).instantiate()
	mouse.position = Vector2(270, 217)
	add_child(mouse)
	await _frames(12)
	await _shot("mouse_idle")
	print("CAPTURE DONE")
	get_tree().quit(0)
