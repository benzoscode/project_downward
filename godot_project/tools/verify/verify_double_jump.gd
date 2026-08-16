extends Node
## M4 二段跳自动断言：无靴 3 格 / 有靴 5 格 / 0.2s 防误触窗口 / 重置水平速度。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_double_jump.gd

const SURFACE_Y := 384.0
const SPAWN := Vector2(320, SURFACE_Y - 10.0)

var _player: CharacterBody2D
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


func _settle() -> void:
	for i in range(120):
		await get_tree().physics_frame
		if _player.is_on_floor() and absf(_player.velocity.y) < 1.0:
			return


func _tap_jump() -> void:
	Input.action_press(&"jump")
	await get_tree().physics_frame
	Input.action_release(&"jump")


## 起跳并追踪最高点；double_at_frame >= 0 时在指定帧补二段跳
func _measure_apex(double_at_frame: int) -> float:
	await _settle()
	var ground_y: float = _player.position.y
	await _tap_jump()
	var min_y := ground_y
	for i in range(120):
		await get_tree().physics_frame
		if i == double_at_frame:
			await _tap_jump()
		min_y = minf(min_y, _player.position.y)
		if _player.is_on_floor() and i > double_at_frame + 20 and _player.position.y >= ground_y - 1.0:
			break
	return ground_y - min_y


func _run_tests() -> void:
	GameState.has_boots = false
	await _settle()

	# T1 无靴：按跳两次也只有 3 格（48px±3）
	var apex1 := await _measure_apex(10)
	_check("T1 无靴无二段跳（3 格）", apex1 >= 45.0 and apex1 <= 51.0,
		"apex=%.1f，期望 45~51" % apex1)

	# T2 有靴：顶点（0.35s≈21 帧）接二段跳，合计 5 格（80px±4）
	GameState.has_boots = true
	var apex2 := await _measure_apex(21)
	_check("T2 有靴二段跳合计 5 格", apex2 >= 74.0 and apex2 <= 86.0,
		"apex=%.1f，期望 74~86" % apex2)

	# T3 防误触：起跳 0.1s（6 帧）内按跳不触发二段跳
	var apex3 := await _measure_apex(6)
	_check("T3 0.2s 窗口内不触发", apex3 >= 45.0 and apex3 <= 51.0,
		"apex=%.1f，期望 45~51" % apex3)

	# T4 二段跳重置水平速度：空中换向，二段跳后 vx 立即为 -48
	await _settle()
	Input.action_press(&"move_right")
	await _physics_frames(30)
	await _tap_jump()
	await _physics_frames(21)
	Input.action_release(&"move_right")
	Input.action_press(&"move_left")
	await _tap_jump()
	await get_tree().physics_frame
	var vx: float = _player.velocity.x
	Input.action_release(&"move_left")
	_check("T4 二段跳重置水平速度", vx <= -44.0,
		"vx=%.1f，期望 <=-44" % vx)

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
