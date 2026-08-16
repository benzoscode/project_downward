extends Node
## M2 光照系统自动断言：光敏水晶在照射 2s 后激活、遮挡不激活、关灯不激活、超程不激活。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_lighting.gd

const SURFACE_Y := 384.0
const SPAWN := Vector2(160, SURFACE_Y - 10.0)

var _player: CharacterBody2D
var _lamp: Node2D
var _failures: int = 0
var _passed: int = 0


func _ready() -> void:
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1280, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(640, SURFACE_Y + 16.0)
	add_child(floor_body)

	_player = (load("res://scenes/characters/player.tscn") as PackedScene).instantiate()
	_player.position = SPAWN
	add_child(_player)
	_lamp = _player.get_node("Lamp")
	GameState.has_lamp = true
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


func _spawn_crystal(pos: Vector2, id: StringName) -> Node2D:
	var crystal := (load("res://scenes/interactables/light_crystal.tscn") as PackedScene).instantiate() as Node2D
	crystal.position = pos
	crystal.set("target_id", id)
	add_child(crystal)
	return crystal


func _run_tests() -> void:
	MechanismBus.reset_all()
	await _physics_frames(10) # 落地 + Lamp 注册

	# T1 关灯：照射位正确也不激活
	var c1 := _spawn_crystal(SPAWN + Vector2(64, 0), &"crystal_a")
	_lamp.call("lock_aim_to", c1.global_position)
	await _physics_frames(150) # 2.5s
	_check("T1 关灯不激活", not c1.call("is_activated"),
		"activated=%s" % c1.call("is_activated"))

	# T2 开灯照射 2s 激活并广播
	_lamp.call("set_lamp_on", true)
	await _physics_frames(150)
	_check("T2 照射 2s 激活并发信号", c1.call("is_activated") and MechanismBus.is_triggered(&"crystal_a"),
		"activated=%s bus=%s" % [c1.call("is_activated"), MechanismBus.is_triggered(&"crystal_a")])
	c1.queue_free()

	# T3 遮挡：灯与水晶之间立墙，射线被挡 → 不激活
	MechanismBus.reset_all()
	var wall := StaticBody2D.new()
	var wall_shape := CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size = Vector2(16, 96)
	wall_shape.shape = wall_rect
	wall.add_child(wall_shape)
	wall.position = SPAWN + Vector2(96, -32)
	add_child(wall)
	var c2 := _spawn_crystal(SPAWN + Vector2(128, 0), &"crystal_b")
	_lamp.call("lock_aim_to", c2.global_position)
	await _physics_frames(150)
	_check("T3 遮挡不激活", not c2.call("is_activated"),
		"activated=%s" % c2.call("is_activated"))
	c2.queue_free()
	wall.queue_free()

	# T4 超程：7 格（112px）外不激活（射程 6 格 = 96px）
	var c3 := _spawn_crystal(SPAWN + Vector2(112, 0), &"crystal_c")
	_lamp.call("lock_aim_to", c3.global_position)
	await _physics_frames(150)
	_check("T4 超出射程不激活", not c3.call("is_activated"),
		"activated=%s" % c3.call("is_activated"))
	c3.queue_free()

	# T5 灯光跟随脸部朝向：向左走后灯朝左（≈π），向右回正（≈0）
	_lamp.set("aim_locked", false)
	Input.action_press(&"move_left")
	await _physics_frames(10)
	Input.action_release(&"move_left")
	await _physics_frames(40)
	var rot_left: float = absf(_lamp.global_rotation)
	Input.action_press(&"move_right")
	await _physics_frames(10)
	Input.action_release(&"move_right")
	await _physics_frames(40)
	var rot_right: float = absf(_lamp.global_rotation)
	_check("T5 灯光跟随转身", rot_left > PI - 0.3 and rot_right < 0.3,
		"left=%.2f right=%.2f" % [rot_left, rot_right])

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
