extends Node
## 机关三批自动断言：单向平台（下穿/上站/S 不掉）+ 光球发射器（初速方向/冷却/缓降/消散）+ 点动按钮。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_mechanisms3.gd

const SURFACE_Y := 384.0
const SPAWN := Vector2(160, SURFACE_Y - 10.0)

var _player: CharacterBody2D
var _failures: int = 0
var _passed: int = 0


func _ready() -> void:
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1600, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(800, SURFACE_Y + 16.0)
	add_child(floor_body)

	var spawn := Marker2D.new()
	spawn.add_to_group(&"spawn_point")
	spawn.position = SPAWN
	add_child(spawn)

	_player = (load("res://scenes/characters/player.tscn") as PackedScene).instantiate()
	_player.position = SPAWN
	add_child(_player)
	_run_tests()


func _check(test_name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_passed += 1
		print("[PASS] ", test_name)
	else:
		_failures += 1
		printerr("[FAIL] ", test_name, " | ", detail)


func _physics_frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


func _count_orbs() -> int:
	var n := 0
	for node in get_tree().current_scene.get_children():
		if node is LightOrb:
			n += 1
	for node in get_children():
		if node is LightOrb:
			n += 1
	return n


func _run_tests() -> void:
	MechanismBus.reset_all()
	await _physics_frames(20)

	# ---- T1 单向平台：从下方跳跃穿越到平台上方站稳（平台 2 格高，跳高 3 格有 1 格余量）----
	var platform := (load("res://scenes/interactables/one_way_platform.tscn") as PackedScene).instantiate() as Node2D
	platform.position = Vector2(400, SURFACE_Y - 32.0)
	add_child(platform)
	_player.position = Vector2(400, SURFACE_Y - 10.0)
	_player.velocity = Vector2.ZERO
	_player.reset_physics_interpolation()
	await _physics_frames(5)
	Input.action_press(&"jump")
	await get_tree().physics_frame
	Input.action_release(&"jump")
	# 上升阶段应穿越（不被挡），随后落稳在平台上
	await _physics_frames(90)
	var expect_y := SURFACE_Y - 32.0 - 3.0 - 10.0 # 平台顶面=原点-半厚3，玩家中心再减半身 10
	var on_top: bool = _player.is_on_floor() and absf(_player.position.y - expect_y) < 3.0
	_check("T1 单向平台下方穿越后站顶", on_top,
		"y=%.1f expect=%.1f floor=%s" % [_player.position.y, expect_y, _player.is_on_floor()])

	# ---- T2 平台上按 S 不下落（严格单向，无下落键）----
	Input.action_press(&"move_down")
	await _physics_frames(30)
	Input.action_release(&"move_down")
	var stayed: bool = _player.is_on_floor() and absf(_player.position.y - expect_y) < 3.0
	_check("T2 按 S 不掉落", stayed, "y=%.1f floor=%s" % [_player.position.y, _player.is_on_floor()])
	_player.position = SPAWN
	_player.velocity = Vector2.ZERO
	platform.queue_free()
	await _physics_frames(5)

	# ---- T3 光球发射：方向初速 + 重力缓降 ----
	var launcher := (load("res://scenes/interactables/orb_launcher.tscn") as PackedScene).instantiate() as Node2D
	launcher.position = Vector2(300, SURFACE_Y - 32.0)
	launcher.set("listen_id", &"launch_a")
	launcher.set("launch_speed", 120.0)
	launcher.set("orb_lifetime", 10.0)
	add_child(launcher)
	await _physics_frames(3)
	MechanismBus.pulse(&"launch_a")
	await get_tree().physics_frame
	var orb := _find_orb()
	var fired := orb != null
	var vx_ok := false
	var vy0_ok := false
	if fired:
		vx_ok = orb.velocity.x > 100.0 # 初速主要沿 +X
		vy0_ok = absf(orb.velocity.y) < 20.0 # 初始几乎无垂直分量
	_check("T3 发射初速沿布置方向", fired and vx_ok and vy0_ok,
		"fired=%s vx=%.1f vy=%.1f" % [fired, orb.velocity.x if orb else -1.0, orb.velocity.y if orb else -1.0])

	# ---- T4 缓降：1 秒内下落速度被限制（远小于自由落体）----
	await _physics_frames(60)
	orb = _find_orb()
	var slow_fall := false
	if orb != null:
		slow_fall = orb.velocity.y <= 43.0 # 终速上限 42 + 1 帧余量
	_check("T4 光球减慢坠落", orb != null and slow_fall,
		"1s 后 vy=%.1f，期望 ≤43" % (orb.velocity.y if orb else -1.0))

	# ---- T5 冷却：全新发射器，首发后立即再按被吞，冷却 1s 后可再发 ----
	var launcher3 := (load("res://scenes/interactables/orb_launcher.tscn") as PackedScene).instantiate() as Node2D
	launcher3.position = Vector2(700, SURFACE_Y - 32.0)
	launcher3.set("listen_id", &"launch_c")
	add_child(launcher3)
	await _physics_frames(3)
	var before := _count_orbs()
	MechanismBus.pulse(&"launch_c")
	await get_tree().physics_frame
	var first := _count_orbs() == before + 1
	MechanismBus.pulse(&"launch_c") # 立即再按：应被冷却吞掉
	await get_tree().physics_frame
	var blocked := _count_orbs() == before + 1
	await _physics_frames(70) # 等过 1s 冷却
	MechanismBus.pulse(&"launch_c")
	await get_tree().physics_frame
	var fired_again := _count_orbs() == before + 2
	_check("T5 1s 发射冷却", first and blocked and fired_again,
		"first=%s blocked=%s again=%s orbs=%d" % [first, blocked, fired_again, _count_orbs()])
	launcher3.queue_free()

	# ---- T6 存活期消散：短寿命发射器单独验证 ----
	var launcher2 := (load("res://scenes/interactables/orb_launcher.tscn") as PackedScene).instantiate() as Node2D
	launcher2.position = Vector2(500, SURFACE_Y - 32.0)
	launcher2.set("listen_id", &"launch_b")
	launcher2.set("orb_lifetime", 0.5)
	add_child(launcher2)
	await _physics_frames(3)
	var before_b := _count_orbs()
	MechanismBus.pulse(&"launch_b")
	await get_tree().physics_frame
	var spawned := _count_orbs() == before_b + 1
	await _physics_frames(50) # 0.5s 寿命 + 余量
	_check("T6 光球到时消散", spawned and _count_orbs() == before_b,
		"spawned=%s orbs=%d，期望回 %d" % [spawned, _count_orbs(), before_b])
	launcher.queue_free()
	launcher2.queue_free()

	# ---- T7 点动按钮：连按两次都触发（非开关切换）----
	MechanismBus.reset_all()
	var trigger_count := [0]
	MechanismBus.triggered.connect(func(id: StringName) -> void:
		if id == &"momentary_test":
			trigger_count[0] += 1)
	var button := (load("res://scenes/interactables/lion_button.tscn") as PackedScene).instantiate()
	button.set("target_id", &"momentary_test")
	button.set("momentary", true)
	add_child(button)
	await _physics_frames(3)
	button.interact()
	await get_tree().physics_frame
	button.interact()
	await get_tree().physics_frame
	_check("T7 点动按钮连按连发", trigger_count[0] == 2,
		"trigger 次数=%d，期望 2" % trigger_count[0])
	button.queue_free()

	# ---- T8 摇杆平台：摇杆与平台分离摆放（platform_offset），按住 E 平台移向终点 ----
	var lever := (load("res://scenes/interactables/lever_platform.tscn") as PackedScene).instantiate() as Node2D
	lever.position = Vector2(800, SURFACE_Y - 8.0)
	lever.set("platform_offset", Vector2(0, -64)) # 平台在摇杆正上方 4 格
	lever.set("move_offset", Vector2(96, 0))
	lever.set("move_speed", 96.0)
	add_child(lever)
	await _physics_frames(3)
	var pf := lever.get_node("Platform") as AnimatableBody2D
	var start_ok := pf.global_position.distance_to(lever.global_position + Vector2(0, -64)) < 2.0
	_player.global_position = lever.global_position
	_player.velocity = Vector2.ZERO
	_player.reset_physics_interpolation()
	await _physics_frames(5)
	Input.action_press(&"interact")
	await _physics_frames(80) # 1s+，96px 位移应走完
	Input.action_release(&"interact")
	var moved := pf.global_position.distance_to(lever.global_position + Vector2(96, -64)) < 6.0
	_check("T8 摇杆平台分离摆放+按 E 移动", start_ok and moved,
		"start_ok=%s moved=%s platform=%s" % [start_ok, moved, pf.global_position])
	lever.queue_free()

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _find_orb() -> LightOrb:
	for node in get_tree().current_scene.get_children():
		if node is LightOrb:
			return node
	for node in get_children():
		if node is LightOrb:
			return node
	return null
