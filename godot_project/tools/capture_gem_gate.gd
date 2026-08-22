extends Node
## 新积木截图：宝石门（空槽/镶嵌满后开启）+ 呼吸灯（暗/亮对比）。
## 输出 tools/out/gem_gate_*.png。用法（godot_project/ 下，非 headless）：
##   & <godot_console.exe> res://scenes/test/verify_host.tscn --position -2000,100 -- res://tools/capture_gem_gate.gd


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://tools/out/")
	MechanismBus.reset_all()
	GameState.gems = [&"gem_jade", &"gem_amber", &"gem_violet"]
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(640, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(320, 250)
	add_child(floor_body)

	var gate := (load("res://scenes/interactables/gem_gate.tscn") as PackedScene).instantiate() as Node2D
	gate.position = Vector2(200, 226)
	add_child(gate)
	var lamp := (load("res://scenes/interactables/breathing_light.tscn") as PackedScene).instantiate() as Node2D
	lamp.position = Vector2(360, 220)
	lamp.set("light_color", Color(1.0, 0.6, 0.3))
	lamp.set("period", 2.0)
	add_child(lamp)

	var camera := Camera2D.new()
	camera.position = Vector2(240, 180)
	camera.zoom = Vector2(2, 2)
	camera.enabled = true
	add_child(camera)
	_run(gate, lamp)


func _run(gate: Node2D, lamp: Node2D) -> void:
	for i in range(8):
		await get_tree().physics_frame
	await _shot("gem_gate_empty_breath")
	# 镶嵌全部三颗宝石 → 开门
	for i in range(3):
		gate.call("interact")
		await get_tree().physics_frame
	for i in range(40):
		await get_tree().physics_frame
	await _shot("gem_gate_open")
	print("CAPTURE DONE")
	get_tree().quit(0)


func _shot(tag: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "res://tools/out/gem_gate_" + tag + ".png"
	if get_tree().root.get_texture().get_image().save_png(path) == OK:
		print("saved: ", path)
