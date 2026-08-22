extends Node
## 按钮正式素材截图（2026-08-20）：狮子头按钮（弹起/按下）+ 彩色按钮 红/蓝/琥珀/绿。
## 输出 tools/out/button_new.png。用法（godot_project/ 下，非 headless）：
##   & <godot_console.exe> res://scenes/test/verify_host.tscn --position -2000,100 -- res://tools/capture_buttons.gd

const COLORS: Array[StringName] = [&"red", &"blue", &"amber", &"green"]


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://tools/out/")
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(480, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(240, 248)
	add_child(floor_body)

	var lion := (load("res://scenes/interactables/lion_button.tscn") as PackedScene).instantiate() as Node2D
	lion.position = Vector2(140, 232)
	add_child(lion)
	var lion_down := (load("res://scenes/interactables/lion_button.tscn") as PackedScene).instantiate() as Node2D
	lion_down.position = Vector2(180, 232)
	add_child(lion_down)
	lion_down.set("target_id", &"cap_one_shot")
	lion_down.set("one_shot", true)

	for i in range(COLORS.size()):
		var btn := (load("res://scenes/interactables/color_button.tscn") as PackedScene).instantiate() as Node2D
		btn.position = Vector2(230.0 + i * 36.0, 232.0)
		add_child(btn)
		btn.set("color_id", COLORS[i])

	var camera := Camera2D.new()
	camera.position = Vector2(240, 200)
	camera.zoom = Vector2(2, 2)
	camera.enabled = true
	add_child(camera)
	_run(lion_down)


func _run(lion_down: Node2D) -> void:
	for i in range(10):
		await get_tree().physics_frame
	lion_down.call("interact") # 按下态（一次性按钮 → 压暗）
	for i in range(10):
		await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "res://tools/out/button_new.png"
	if get_tree().root.get_texture().get_image().save_png(path) == OK:
		print("screenshot saved: ", path)
	print("CAPTURE DONE")
	get_tree().quit(0)
