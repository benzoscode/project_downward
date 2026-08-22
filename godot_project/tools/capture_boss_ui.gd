extends Node
## Boss 正式素材 + 告示牌/石碑（2026-08-20）截图。
## 输出 tools/out/boss_ui.png。用法（godot_project/ 下，非 headless）：
##   & <godot_console.exe> res://scenes/test/verify_host.tscn --position -2000,100 -- res://tools/capture_boss_ui.gd


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

	var boss := (load("res://scenes/characters/boss.tscn") as PackedScene).instantiate() as Node2D
	boss.position = Vector2(200, 214)
	add_child(boss)

	var sign := (load("res://scenes/interactables/sign.tscn") as PackedScene).instantiate() as Node2D
	sign.position = Vector2(300, 240)
	add_child(sign)
	var stone := (load("res://scenes/interactables/sign.tscn") as PackedScene).instantiate() as Node2D
	stone.position = Vector2(340, 240)
	add_child(stone)
	stone.set("sign_texture", load("res://assets/props/sign_stone.png"))

	var camera := Camera2D.new()
	camera.position = Vector2(240, 180)
	camera.zoom = Vector2(2, 2)
	camera.enabled = true
	add_child(camera)
	_run(boss)


func _run(boss: Node2D) -> void:
	for i in range(10):
		await get_tree().physics_frame
	# 待机态截图后切到追击（move）再截
	boss.call("_change_state", 2)
	for i in range(6):
		await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "res://tools/out/boss_ui.png"
	if get_tree().root.get_texture().get_image().save_png(path) == OK:
		print("saved: ", path)
	print("anim=", boss.get_node("AnimatedSprite2D").animation)
	print("CAPTURE DONE")
	get_tree().quit(0)
