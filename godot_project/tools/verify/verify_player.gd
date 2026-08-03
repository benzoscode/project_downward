extends SceneTree
## M1 玩家 3C 自动断言（AGENTS.md §8.4），策划案数值：移速 3 格/秒、跳跃 3 格。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless --script tools/verify/verify_player.gd
## 全部通过退出码 0，任一失败退出码 1。

const TILE := 16.0
const SURFACE_Y := 384.0 # 地板表面（StaticBody2D 顶边）
const SPAWN := Vector2(320, SURFACE_Y - 10.0) # 玩家判定 12×20，中心在表面上方 10px

var _player: CharacterBody2D
var _floor: StaticBody2D
var _failures: int = 0
var _passed: int = 0
var _done: bool = false


func _initialize() -> void:
	_floor = StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(640, 32)
	shape.shape = rect
	_floor.add_child(shape)
	_floor.position = Vector2(320, SURFACE_Y + 16.0)
	root.add_child(_floor)

	var scene := load("res://scenes/characters/player.tscn") as PackedScene
	_player = scene.instantiate() as CharacterBody2D
	_player.position = SPAWN
	root.add_child(_player)
	_run_tests()


func _process(_delta: float) -> bool:
	return _done


func _check(test_name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_passed += 1
		print("[PASS] ", test_name)
	else:
		_failures += 1
		printerr("[FAIL] ", test_name, " | ", detail)


func _press(action: StringName) -> void:
	Input.action_press(action)


func _release(action: StringName) -> void:
	Input.action_release(action)


## 等玩家落地停稳（最多 2 秒）
func _settle() -> void:
	for i in range(120):
		await physics_frame
		if _player.is_on_floor() and absf(_player.velocity.y) < 1.0:
			return


func _run_tests() -> void:
	await _settle()

	# T1 起步惯性：按右 2 帧后速度应明显大于 0 但未达满速（48px/s）
	_press(&"move_right")
	await physics_frame
	await physics_frame
	var early_speed := absf(_player.velocity.x)
	_check(
		"T1 起步惯性（非瞬时满速）",
		early_speed > 3.0 and early_speed < 45.0,
		"2 帧后速度=%.1f，期望 3~45" % early_speed
	)

	# T2 最高速度：持续按右至 60 帧，应达 3 格/秒 = 48px/s
	for i in range(58):
		await physics_frame
	var max_speed := absf(_player.velocity.x)
	_check(
		"T2 移动速度 3 格/秒",
		max_speed >= 44.0 and max_speed <= 52.0,
		"满速=%.1f，期望 44~52" % max_speed
	)

	# T3 松手减速：应在 3~15 帧内停下（有惯性但不拖沓）
	_release(&"move_right")
	var stop_frames := 0
	while absf(_player.velocity.x) > 2.0 and stop_frames < 30:
		await physics_frame
		stop_frames += 1
	_check(
		"T3 松手惯性停步",
		stop_frames >= 2 and stop_frames <= 15,
		"停下用了 %d 帧，期望 2~15" % stop_frames
	)

	# T4 跳跃高度：3 格 = 48px（±3px 容差）
	await _settle()
	var ground_y := _player.position.y
	_press(&"jump")
	await physics_frame
	_release(&"jump")
	var min_y := ground_y
	for i in range(90):
		await physics_frame
		min_y = minf(min_y, _player.position.y)
		if _player.is_on_floor() and _player.position.y >= ground_y - 1.0 and i > 10:
			break
	var apex := ground_y - min_y
	_check(
		"T4 跳跃高度 3 格",
		apex >= 45.0 and apex <= 51.0,
		"顶点高度=%.1fpx，期望 45~51" % apex
	)

	# T5 土狼时间：离地 2~3 帧（远小于 0.1s 宽限）按跳应起跳
	await _settle()
	root.remove_child(_floor)
	for i in range(3):
		await physics_frame
	_press(&"jump")
	await physics_frame
	_release(&"jump")
	await physics_frame
	var coyote_vy := _player.velocity.y
	_check(
		"T5 土狼时间生效",
		coyote_vy < -150.0,
		"离地后起跳 vy=%.1f，期望 < -150" % coyote_vy
	)

	# T6 跳跃缓冲：下落至距地面约 14px 时按跳，落地后应自动起跳
	_player.position = SPAWN + Vector2(0, -74.0)
	_player.velocity = Vector2.ZERO
	root.add_child(_floor)
	var pressed := false
	for i in range(120):
		await physics_frame
		var distance := SURFACE_Y - (_player.position.y + 10.0)
		if not pressed and distance < 14.0 and _player.velocity.y > 0.0:
			_press(&"jump")
			await physics_frame
			_release(&"jump")
			pressed = true
		if pressed and _player.velocity.y < -150.0:
			break
	_check(
		"T6 跳跃缓冲生效",
		pressed and _player.velocity.y < -150.0,
		"pressed=%s，落地后 vy=%.1f" % [pressed, _player.velocity.y]
	)

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	_done = true
	quit(1 if _failures > 0 else 0)
