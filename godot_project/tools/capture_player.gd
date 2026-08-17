extends Node
## 主角正式素材近景截图：无灯待机 / 有灯待机 / 有灯走路 三张。
## 输出 tools/out/player_new_*.png。用法（godot_project/ 下）：
##   & <godot_console.exe> res://scenes/test/verify_host.tscn --position -2000,100 -- res://tools/capture_player.gd

var _player: CharacterBody2D
var _lamp: Node2D


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://tools/out/")
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
	camera.zoom = Vector2(2, 2) # 2 倍近景看像素
	camera.enabled = true
	add_child(camera)
	_run()


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


func _shot(tag: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "res://tools/out/player_new_" + tag + ".png"
	if get_tree().root.get_texture().get_image().save_png(path) == OK:
		print("screenshot saved: ", path)


func _run() -> void:
	await _frames(30)
	await _shot("idle")
	_lamp.call("set_lamp_on", true)
	await _frames(20)
	await _shot("idle_lamp")
	# 模拟走路：给水平速度并关掉减速（headless 无输入，减速会立刻刹停）
	_player.set("deceleration", 0.0)
	_player.velocity.x = 48.0
	await _frames(15)
	await _shot("run_lamp")
	print("CAPTURE DONE")
	get_tree().quit(0)
