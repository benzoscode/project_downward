extends Node
## M6 机关二批自动断言：交替平台/摇杆平台/双按钮门/滞后组件/草丛光透/顺序机关/虚空平台/输入延迟。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_mechanisms2.gd

const SURFACE_Y := 384.0
const SPAWN := Vector2(120, SURFACE_Y - 10.0)

var _player: CharacterBody2D
var _failures: int = 0
var _passed: int = 0


func _ready() -> void:
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1920, 32)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(960, SURFACE_Y + 16.0)
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


func _settle() -> void:
	for i in range(120):
		await get_tree().physics_frame
		if _player.is_on_floor() and absf(_player.velocity.y) < 1.0:
			return


func _run_tests() -> void:
	MechanismBus.reset_all()
	await _settle()

	# T1 交替平台：A/B 反相，且各自随时间翻转
	var pa := _spawn("res://scenes/interactables/alternating_platform.tscn", Vector2(600, SURFACE_Y - 48))
	pa.set("period", 0.4)
	pa.set("group_b", false)
	var pb := _spawn("res://scenes/interactables/alternating_platform.tscn", Vector2(700, SURFACE_Y - 48))
	pb.set("period", 0.4)
	pb.set("group_b", true)
	await _physics_frames(3)
	var a1: bool = pa.call("is_solid")
	var b1: bool = pb.call("is_solid")
	var flipped := false
	for i in range(30):
		await get_tree().physics_frame
		if pa.call("is_solid") != a1:
			flipped = true
			break
	_check("T1 交替平台反相且翻转", a1 != b1 and flipped,
		"a=%s b=%s flipped=%s" % [a1, b1, flipped])
	pa.queue_free()
	pb.queue_free()

	# T2 摇杆平台：按住 E 平台前进，松开复位
	var lever := _spawn("res://scenes/interactables/lever_platform.tscn", SPAWN + Vector2(16, 0))
	lever.set("move_offset", Vector2(96, 0))
	lever.set("move_speed", 64.0)
	await _physics_frames(5)
	var platform: Node2D = lever.get_node("Platform")
	var home_x: float = platform.position.x
	Input.action_press(&"interact")
	await _physics_frames(60) # 1s → 应前进约 64px
	var moved: float = platform.position.x - home_x
	Input.action_release(&"interact")
	await _physics_frames(60) # 停留 0.5s 内不应复位
	var dwelling := platform.position.x - home_x
	await _physics_frames(120) # 停留结束 + 回程（96px/64px/s=1.5s）
	var returned: float = absf(platform.position.x - home_x)
	_check("T2 摇杆平台前进/停留/复位", moved > 30.0 and dwelling > 30.0 and returned < 2.0,
		"moved=%.1f dwell=%.1f returned=%.2f" % [moved, dwelling, returned])
	lever.queue_free()

	# T3 双按钮门：双触发才开，解除后 2s 关闭
	var door := _spawn("res://scenes/interactables/dual_button_door.tscn", Vector2(500, SURFACE_Y - 24))
	var ids: Array[StringName] = [&"da", &"db"]
	door.set("listen_ids", ids)
	await _physics_frames(3)
	MechanismBus.trigger(&"da")
	await _physics_frames(10)
	var still_closed: bool = not door.call("is_open")
	MechanismBus.trigger(&"db")
	await _physics_frames(40)
	var opened: bool = door.call("is_open")
	MechanismBus.release(&"da")
	await _physics_frames(30) # 0.5s 后仍开
	var grace: bool = door.call("is_open")
	await _physics_frames(120) # 累计超 2s
	var closed_later: bool = not door.call("is_open")
	_check("T3 双按钮门逻辑", still_closed and opened and grace and closed_later,
		"closed=%s open=%s grace=%s later=%s" % [still_closed, opened, grace, closed_later])
	door.queue_free()

	# T4 滞后组件：延迟 1s 才触发
	var relay := _spawn("res://scenes/interactables/trigger_relay.tscn", Vector2(800, SURFACE_Y))
	relay.set("input_id", &"rin")
	relay.set("output_id", &"rout")
	relay.set("delay", 1.0)
	await _physics_frames(3)
	MechanismBus.trigger(&"rin")
	await _physics_frames(30) # 0.5s：未触发
	var early := MechanismBus.is_triggered(&"rout")
	await _physics_frames(50) # 累计约 1.3s：已触发
	var late := MechanismBus.is_triggered(&"rout")
	_check("T4 滞后组件延迟生效", not early and late,
		"early=%s late=%s" % [early, late])
	relay.queue_free()

	# T5 草丛光透：照亮后透明
	var grass := _spawn("res://scenes/interactables/grass_cover.tscn", SPAWN + Vector2(48, 0))
	await _physics_frames(5)
	var hidden: bool = not grass.call("is_revealed")
	GameState.has_lamp = true
	var lamp := _player.get_node("Lamp")
	lamp.call("set_lamp_on", true)
	lamp.call("lock_aim_to", grass.global_position)
	await _physics_frames(10)
	var revealed: bool = grass.call("is_revealed")
	lamp.call("set_lamp_on", false)
	_check("T5 草丛照亮显现", hidden and revealed,
		"hidden=%s revealed=%s" % [hidden, revealed])
	grass.queue_free()

	# T6 顺序机关：按错清零，按对触发
	var ctrl := _spawn("res://scenes/interactables/sequence_controller.tscn", Vector2(900, SURFACE_Y))
	ctrl.set("sequence_id", &"seq1")
	var seq: Array[StringName] = [&"red", &"green"]
	ctrl.set("expected", seq)
	ctrl.set("target_id", &"seq_done")
	var btn_red := _spawn("res://scenes/interactables/color_button_red.tscn", SPAWN + Vector2(16, 0))
	btn_red.set("color_id", &"red")
	btn_red.set("sequence_id", &"seq1")
	var btn_green := _spawn("res://scenes/interactables/color_button_red.tscn", SPAWN + Vector2(16, 0))
	btn_green.set("color_id", &"green")
	btn_green.set("sequence_id", &"seq1")
	await _physics_frames(5)
	btn_green.call("interact") # 先按绿（错）→ 进度应为 0
	var wrong_progress: int = ctrl.call("get_progress")
	btn_red.call("interact")
	btn_green.call("interact")
	_check("T6 顺序机关", wrong_progress == 0 and MechanismBus.is_triggered(&"seq_done"),
		"wrong=%d done=%s" % [wrong_progress, MechanismBus.is_triggered(&"seq_done")])

	# T7 虚空平台：从上方落下直接穿过
	var fake := _spawn("res://scenes/interactables/fake_platform.tscn", Vector2(1100, SURFACE_Y - 32))
	await _physics_frames(3)
	_player.position = Vector2(1124, SURFACE_Y - 96) # 平台上方 4 格
	_player.velocity = Vector2.ZERO
	_player.reset_physics_interpolation()
	await _physics_frames(90)
	var fell_through := _player.position.y > SURFACE_Y - 12.0
	_check("T7 虚空平台可穿过", fell_through,
		"y=%.1f，期望落到地面" % _player.position.y)
	fake.queue_free()

	# T8 玩家输入延迟（致幻降级方案）：0.5s 延迟
	_player.input_delay = 0.5
	_player.position = SPAWN
	_player.velocity = Vector2.ZERO
	_player.reset_physics_interpolation()
	await _settle()
	await _physics_frames(90) # 清空输入历史
	Input.action_press(&"move_right")
	await _physics_frames(15) # 0.25s：尚无响应
	var early_v := absf(_player.velocity.x)
	await _physics_frames(30) # 累计约 0.75s：已响应
	var late_v := absf(_player.velocity.x)
	Input.action_release(&"move_right")
	_check("T8 玩家输入延迟", early_v < 5.0 and late_v > 30.0,
		"early=%.1f late=%.1f" % [early_v, late_v])

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
