extends Node
## 石牌/木梯/吊桥默认锚点截图（2026-08-20）。输出 tools/out/opt_*.png。
## 用法：& <godot_console.exe> res://scenes/test/verify_host.tscn --position -2000,100 -- res://tools/capture_options.gd


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://tools/out/")
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(640, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(320, 250)
	add_child(floor_body)

	# 木梯 + 石牌 + 木牌 并列
	var ladder := (load("res://scenes/interactables/ladder.tscn") as PackedScene).instantiate() as Node2D
	ladder.position = Vector2(120, 250)
	add_child(ladder)
	var ladder2 := (load("res://scenes/interactables/ladder_plain.tscn") as PackedScene).instantiate() as Node2D
	ladder2.position = Vector2(170, 250)
	add_child(ladder2)
	var stone := (load("res://scenes/interactables/sign_stone.tscn") as PackedScene).instantiate() as Node2D
	stone.position = Vector2(260, 240)
	add_child(stone)
	var wood := (load("res://scenes/interactables/sign.tscn") as PackedScene).instantiate() as Node2D
	wood.position = Vector2(300, 240)
	add_child(wood)
	# 吊桥默认锚点
	var bridge := (load("res://scenes/interactables/lever_drawbridge.tscn") as PackedScene).instantiate() as Node2D
	bridge.position = Vector2(450, 250)
	add_child(bridge)

	var camera := Camera2D.new()
	camera.position = Vector2(300, 170)
	camera.zoom = Vector2(2, 2)
	camera.enabled = true
	add_child(camera)
	_run()


func _run() -> void:
	for i in range(10):
		await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "res://tools/out/opt_options.png"
	if get_tree().root.get_texture().get_image().save_png(path) == OK:
		print("saved: ", path)
	print("CAPTURE DONE")
	get_tree().quit(0)
