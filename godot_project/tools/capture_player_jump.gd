extends Node
## 主角跳跃新素材截图（2026-08-20）：上升/下落 × 无灯/有灯 四张。
## 输出 tools/out/player_jump_*.png。用法（godot_project/ 下）：
##   & <godot_console.exe> res://scenes/test/verify_host.tscn --position -2000,100 -- res://tools/capture_player_jump.gd

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
	var path := "res://tools/out/player_jump_" + tag + ".png"
	if get_tree().root.get_texture().get_image().save_png(path) == OK:
		print("screenshot saved: ", path)


func _do_jump_cycle(tag_prefix: String) -> void:
	Input.action_press(&"jump")
	await _frames(2)
	Input.action_release(&"jump")
	await _frames(8)
	print(tag_prefix, " rise anim=", _player.get_node("AnimatedSprite2D").animation,
		" vy=", _player.velocity.y)
	await _shot(tag_prefix + "rise")
	while _player.velocity.y < 0.0:
		await get_tree().physics_frame
	await _frames(6)
	print(tag_prefix, " fall anim=", _player.get_node("AnimatedSprite2D").animation,
		" vy=", _player.velocity.y)
	await _shot(tag_prefix + "fall")
	while not _player.is_on_floor():
		await get_tree().physics_frame
	await _frames(5)


func _run() -> void:
	await _frames(30)
	await _do_jump_cycle("")
	_lamp.call("set_lamp_on", true)
	_lamp.call("lock_aim_to", _player.global_position + Vector2(80, -10))
	await _frames(10)
	await _do_jump_cycle("lamp_")
	print("CAPTURE DONE")
	get_tree().quit(0)
