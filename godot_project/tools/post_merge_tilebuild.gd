extends SceneTree
## tilebuild 合并后处理（一次性工具）：
## 1. 策划搭建的 room_01/03/04 灰盒亮度 0.3 → 0.10（对齐 2026-08-17 能见度调校）
## 2. room_01 补回教学链（合并时取了策划版，丢了灰盒教学件）：灯拾取/告示牌/光敏水晶/水晶门
## 用法：& <godot_console.exe> --headless --script tools/post_merge_tilebuild.gd

const DARK := Color(0.10, 0.10, 0.12, 1)


func _initialize() -> void:
	for path in ["res://scenes/rooms/room_01.tscn", "res://scenes/rooms/room_03.tscn", "res://scenes/rooms/room_04.tscn"]:
		_set_darkness(path)
	_fix_room_01()
	print("post-merge done")
	quit(0)


func _set_darkness(path: String) -> void:
	var packed := load(path) as PackedScene
	var room := packed.instantiate() as Node2D
	root.add_child(room)
	room.set("game_darkness", DARK)
	_save(room, path)


func _fix_room_01() -> void:
	var path := "res://scenes/rooms/room_01.tscn"
	var packed := load(path) as PackedScene
	var room := packed.instantiate() as Node2D
	root.add_child(room)
	var mech := room.get_node("Mechanisms")
	if mech.get_node_or_null("TeachLamp") != null:
		print("  room_01 教学链已存在，跳过")
		room.queue_free()
		return
	_add(mech, room, "res://scenes/interactables/pickup.tscn", "TeachLamp", Vector2(6, 12), "item", &"lamp")
	_add(mech, room, "res://scenes/interactables/sign.tscn", "TeachSign", Vector2(31, 12),
		"text", "一块字迹模糊的石碑：\n『以光唤醒宝石，门自会开启。』")
	_add(mech, room, "res://scenes/interactables/light_crystal.tscn", "TeachCrystal", Vector2(35, 12), "target_id", &"r01_crystal")
	_add(mech, room, "res://scenes/interactables/stone_door.tscn", "TeachDoor", Vector2(38, 11), "listen_id", &"r01_crystal")
	_save(room, path)
	print("  room_01 教学链已补")


func _add(parent: Node, room: Node2D, scene: String, node_name: String, tile: Vector2, prop: String, value: Variant) -> void:
	var node := (load(scene) as PackedScene).instantiate() as Node2D
	node.name = node_name
	node.position = tile * 16.0 + Vector2(8, 8)
	node.set(prop, value)
	parent.add_child(node)
	node.owner = room


func _save(room: Node2D, path: String) -> void:
	var out := PackedScene.new()
	if out.pack(room) != OK or ResourceSaver.save(out, path) != OK:
		printerr("save failed: ", path)
		quit(1)
		return
	room.queue_free()
	print("  saved: ", path)
