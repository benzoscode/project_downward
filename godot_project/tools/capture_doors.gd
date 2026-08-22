extends Node
## 石门正式素材截图（2026-08-20）：四种门并排 + 一扇开门动画中帧。
## 输出 tools/out/door_new.png。用法（godot_project/ 下，非 headless）：
##   & <godot_console.exe> res://scenes/test/verify_host.tscn --position -2000,100 -- res://tools/capture_doors.gd

const DOORS := [
	"res://scenes/interactables/stone_door.tscn",
	"res://scenes/interactables/key_door.tscn",
	"res://scenes/interactables/dual_button_door.tscn",
	"res://scenes/interactables/dual_plate_door.tscn",
]


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

	for i in range(DOORS.size()):
		var door := (load(DOORS[i]) as PackedScene).instantiate() as Node2D
		door.position = Vector2(160.0 + i * 56.0, 232.0)
		add_child(door)

	var camera := Camera2D.new()
	camera.position = Vector2(240, 190)
	camera.zoom = Vector2(2, 2)
	camera.enabled = true
	add_child(camera)
	_run()


func _run() -> void:
	for i in range(30):
		await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "res://tools/out/door_new.png"
	if get_tree().root.get_texture().get_image().save_png(path) == OK:
		print("screenshot saved: ", path)
	print("CAPTURE DONE")
	get_tree().quit(0)
