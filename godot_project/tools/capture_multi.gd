extends Node
## 2026-08-20 多资源批截图：鼠鼠动画态 / 二段跳气流 / 交替平台 / 梯子 / 吊桥 / 物品 / 压力板 / 水晶 / 光球。
## 输出 tools/out/multi_*.png。用法（godot_project/ 下，非 headless）：
##   & <godot_console.exe> res://scenes/test/verify_host.tscn --position -2000,100 -- res://tools/capture_multi.gd

var _frames_done := 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://tools/out/")
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1600, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(800, 256)
	add_child(floor_body)

	var camera := Camera2D.new()
	camera.position = Vector2(400, 190)
	camera.zoom = Vector2(2, 2)
	camera.enabled = true
	add_child(camera)
	_run()


func _n(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame
		_frames_done += 1


func _shot(tag: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "res://tools/out/multi_" + tag + ".png"
	if get_tree().root.get_texture().get_image().save_png(path) == OK:
		print("saved: ", path)


func _run() -> void:
	await _n(10)
	# 鼠鼠：待机（已自动播放）；跳跃上升/下降态
	var mouse := (load("res://scenes/characters/mouse.tscn") as PackedScene).instantiate() as CharacterBody2D
	mouse.position = Vector2(120, 246)
	add_child(mouse)
	mouse.velocity = Vector2(0, -100)
	await _n(6)
	await _shot("mouse_jump_rise")
	while mouse.velocity.y < 0.0:
		await get_tree().physics_frame
	await _n(6)
	await _shot("mouse_jump_fall")
	mouse.queue_free()
	await _n(20)
	# 二段跳气流：给玩家靴子，头顶无碰撞 → 起跳+二段跳
	var player := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as CharacterBody2D
	player.position = Vector2(240, 246)
	add_child(player)
	GameState.has_boots = true
	await _n(10)
	Input.action_press(&"jump")
	await _n(2)
	Input.action_release(&"jump")
	await _n(18)
	Input.action_press(&"jump")
	await _n(8)
	await _shot("doublejump_puff")
	Input.action_release(&"jump")
	player.queue_free()
	await _n(20)
	# 交替平台：一实一虚
	var alt := (load("res://scenes/interactables/alternating_platform.tscn") as PackedScene).instantiate() as Node2D
	alt.position = Vector2(420, 200)
	add_child(alt)
	var alt2 := (load("res://scenes/interactables/alternating_platform.tscn") as PackedScene).instantiate() as Node2D
	alt2.position = Vector2(420, 200)
	alt2.set("group_b", true)
	alt2.set("period", 10.0)
	add_child(alt2)
	await _n(5)
	await _shot("alt_platform")
	alt.queue_free()
	alt2.queue_free()
	await _n(5)
	# 梯子（藤梯）+ 吊桥（抬起/放下）
	var ladder := (load("res://scenes/interactables/ladder.tscn") as PackedScene).instantiate() as Node2D
	ladder.position = Vector2(560, 256)
	add_child(ladder)
	var bridge := (load("res://scenes/interactables/lever_drawbridge.tscn") as PackedScene).instantiate() as Node2D
	bridge.position = Vector2(700, 256)
	add_child(bridge)
	await _n(10)
	await _shot("ladder_bridge_down")
	var bridge_node: Node2D = bridge.get_node("Bridge")
	var bridge_coll := bridge.get_node("Bridge/CollisionShape2D") as CollisionShape2D
	bridge_node.position = bridge_node.position + Vector2(0, -48)
	bridge_coll.disabled = true
	await _n(5)
	await _shot("ladder_bridge_up")
	ladder.queue_free()
	bridge.queue_free()
	await _n(10)
	# 物品图标一排
	var items := [&"lamp", &"boots", &"whistle", &"key", &"gem_jade", &"gem_amber", &"gem_violet"]
	for i in range(items.size()):
		var pk := (load("res://scenes/interactables/pickup.tscn") as PackedScene).instantiate() as Node2D
		pk.position = Vector2(40.0 + i * 30.0, 246)
		add_child(pk)
		pk.set("item", items[i])
	await _n(5)
	await _shot("items")
	for child in get_children():
		if child is Area2D and child.position.y > 200.0:
			child.queue_free()
	await _n(10)
	# 压力板（大型抬起/按下）+ 水晶 + 光球（红蓝黄）
	var plate := (load("res://scenes/interactables/pressure_plate.tscn") as PackedScene).instantiate() as Node2D
	plate.position = Vector2(300, 246)
	add_child(plate)
	plate.set("mouse_only", false)
	await _n(5)
	await _shot("plate_up")
	plate.call("interact") if plate.has_method("interact") else null
	# 压力板无 interact；直接触发总线模拟踩下
	MechanismBus.trigger(&"cap_plate_shot")
	await _n(3)
	await _shot("plate_crystal")
	plate.queue_free()
	var crystal := (load("res://scenes/interactables/light_crystal.tscn") as PackedScene).instantiate() as Node2D
	crystal.position = Vector2(360, 246)
	add_child(crystal)
	await _n(5)
	var orb := (load("res://scenes/interactables/light_orb.tscn") as PackedScene).instantiate() as CharacterBody2D
	orb.position = Vector2(430, 246)
	add_child(orb)
	orb.call("setup", Vector2(30, 0), Color(0.95, 0.3, 0.3), 10.0)
	await _n(10)
	await _shot("crystal_orbs")
	crystal.queue_free()
	orb.queue_free()
	await _n(5)
	print("CAPTURE DONE")
	get_tree().quit(0)
