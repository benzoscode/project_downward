extends Node
## 2026-08-20 需求验证：双压力板门 / 摇杆吊桥 / 梯子渲染层级 / 坠落速度减半（到顶高度不变）。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_mechanisms4.gd

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


func _spawn(path: String, pos: Vector2) -> Node2D:
	var node := (load(path) as PackedScene).instantiate() as Node2D
	node.position = pos
	add_child(node)
	return node


func _physics_frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


func _run_tests() -> void:
	MechanismBus.reset_all()
	await _physics_frames(20)

	# ---- T1 双压力板门：两板同踩才开，松一块延迟 1s 关闭 ----
	var door := _spawn("res://scenes/interactables/dual_plate_door.tscn", Vector2(500, SURFACE_Y - 24))
	await _physics_frames(3)
	MechanismBus.trigger(&"plate_a")
	await _physics_frames(10)
	var single_closed: bool = not door.call("is_open")
	MechanismBus.trigger(&"plate_b")
	await _physics_frames(40)
	var both_open: bool = door.call("is_open")
	MechanismBus.release(&"plate_a")
	await _physics_frames(30) # 0.5s < 1s 宽限，仍开
	var grace_open: bool = door.call("is_open")
	await _physics_frames(90) # 累计超 1s
	var closed_later: bool = not door.call("is_open")
	MechanismBus.release(&"plate_b")
	_check("T1 双压力板门逻辑", single_closed and both_open and grace_open and closed_later,
		"single=%s both=%s grace=%s later=%s" % [single_closed, both_open, grace_open, closed_later])
	door.queue_free()

	# ---- T2 摇杆吊桥：按住 E 升起，松开立即缓慢下降回起始位 ----
	var lever := _spawn("res://scenes/interactables/lever_drawbridge.tscn", SPAWN + Vector2(16, 0))
	lever.set("raise_offset", Vector2(0, -48))
	lever.set("raise_speed", 48.0)
	lever.set("lower_speed", 20.0)
	await _physics_frames(5)
	var bridge: Node2D = lever.get_node("Bridge")
	var home_pos: Vector2 = bridge.position
	Input.action_press(&"interact")
	await _physics_frames(70) # 1.17s × 48px/s ≈ 56px → 到顶 48px
	Input.action_release(&"interact")
	var raised: float = home_pos.y - bridge.position.y
	await _physics_frames(30) # 0.5s × 20px/s ≈ 10px 回落（验证立即下降且更慢）
	var partial: float = home_pos.y - bridge.position.y
	await _physics_frames(180) # 3s：足够回到起始位
	var returned: float = bridge.position.distance_to(home_pos)
	_check("T2 摇杆吊桥升起/缓降/回位", raised > 40.0 and partial < raised - 5.0 and partial > 5.0 and returned < 1.5,
		"raised=%.1f partial=%.1f returned=%.2f" % [raised, partial, returned])
	lever.queue_free()

	# ---- T3 梯子渲染层级：梯子视觉必须在角色之下（攀爬不再被遮挡）----
	var ladder := _spawn("res://scenes/interactables/ladder.tscn", Vector2(700, SURFACE_Y))
	await _physics_frames(3)
	var ladder_visual := ladder.get_node("ColorRect") as CanvasItem
	_check("T3 梯子视觉层低于角色", ladder_visual.z_index < _player.z_index,
		"ladder_z=%d player_z=%d" % [ladder_visual.z_index, _player.z_index])
	ladder.queue_free()

	# ---- T4 坠落速度减半且到顶高度不变 ----
	# 从 64px 高处自由落体，峰值坠速应 ≈ sqrt(2·g_up·0.7·h)（旧值 1.4 倍率的 0.707 倍）
	_player.position = Vector2(900, SURFACE_Y - 64.0 - 10.0)
	_player.velocity = Vector2.ZERO
	_player.reset_physics_interpolation()
	await _physics_frames(2)
	var peak_fall := 0.0
	for i in range(120):
		await get_tree().physics_frame
		peak_fall = maxf(peak_fall, _player.velocity.y)
		if _player.is_on_floor():
			break
	# g_up = 2·48/0.35² ≈ 783.7；g_down = 783.7×0.7 ≈ 548.6；v = sqrt(2·548.6·64) ≈ 265
	_check("T4a 坠落峰值速度减半", peak_fall > 220.0 and peak_fall < 300.0,
		"peak=%.1f 期望≈265" % peak_fall)
	# 跳跃到顶高度仍约 3 格（48px）
	var ground_y: float = _player.position.y
	Input.action_press(&"jump")
	await _physics_frames(2)
	Input.action_release(&"jump")
	var apex := 0.0
	for i in range(90):
		await get_tree().physics_frame
		apex = maxf(apex, ground_y - _player.position.y)
		if _player.is_on_floor() and i > 10:
			break
	_check("T4b 到顶高度仍为 3 格", apex > 44.0 and apex < 52.0, "apex=%.1fpx" % apex)

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
