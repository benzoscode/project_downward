extends Node
## 吊桥吊绳升降截图（2026-08-20）。
## 输出 tools/out/drawbridge_*.png。用法（godot_project/ 下，非 headless）：
##   & <godot_console.exe> res://scenes/test/verify_host.tscn --position -2000,100 -- res://tools/capture_drawbridge.gd


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://tools/out/")
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(480, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(240, 260)
	add_child(floor_body)

	var bridge := (load("res://scenes/interactables/lever_drawbridge.tscn") as PackedScene).instantiate() as Node2D
	bridge.position = Vector2(120, 250)
	add_child(bridge)
	bridge.set("rope_anchor_y", -94.0)

	var camera := Camera2D.new()
	camera.position = Vector2(180, 160)
	camera.zoom = Vector2(2, 2)
	camera.enabled = true
	add_child(camera)
	_run(bridge)


func _run(bridge: Node2D) -> void:
	for i in range(8):
		await get_tree().physics_frame
	await _shot("down")
	var bn: Node2D = bridge.get_node("Bridge")
	bn.position = bn.position + Vector2(0, -48)
	await _n(3)
	await _shot("up")
	print("CAPTURE DONE")
	get_tree().quit(0)


func _n(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


func _shot(tag: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "res://tools/out/drawbridge_" + tag + ".png"
	if get_tree().root.get_texture().get_image().save_png(path) == OK:
		print("saved: ", path)
