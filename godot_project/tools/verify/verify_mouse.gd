extends Node
## M5 召唤哨与老鼠自动断言：召唤/操控切换/相机接管/窄缝/输入延迟/压力板权限/死亡冷却。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_mouse.gd

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


func _physics_frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	Input.action_release(action)
	await get_tree().physics_frame


func _mouse() -> Mouse:
	return ControlManager.mouse


func _run_tests() -> void:
	GameState.has_whistle = false
	await _physics_frames(10)

	# T1 无哨不可召唤
	await _tap(&"whistle")
	await _physics_frames(3)
	_check("T1 无哨不可召唤", not ControlManager.is_mouse_out(), "")

	# T2 Q 召唤老鼠
	GameState.has_whistle = true
	await _tap(&"whistle")
	await _physics_frames(3)
	_check("T2 Q 召唤老鼠", ControlManager.is_mouse_out(), "")

	# T3 R 切换：玩家冻结，老鼠响应输入
	await _tap(&"switch_control")
	await _physics_frames(3)
	var player_x := _player.position.x
	var mouse_x := _mouse().position.x
	Input.action_press(&"move_right")
	await _physics_frames(30)
	Input.action_release(&"move_right")
	var player_moved: float = absf(_player.position.x - player_x)
	var mouse_moved: float = _mouse().position.x - mouse_x
	_check("T3 切换后玩家静止/老鼠移动",
		player_moved < 2.0 and mouse_moved > 10.0,
		"player=%.1f mouse=%.1f" % [player_moved, mouse_moved])

	# T4 相机接管：老鼠 pcam 优先级压过玩家（10）
	_check("T4 相机切到老鼠", int(_mouse().get_node("PhantomCamera2D").get("priority")) > 10, "")

	# T5 切回：玩家恢复操控，老鼠停留原地
	await _tap(&"switch_control")
	await _physics_frames(3)
	var mouse_stay_x := _mouse().position.x
	Input.action_press(&"move_right")
	await _physics_frames(30)
	Input.action_release(&"move_right")
	var mouse_drift: float = absf(_mouse().position.x - mouse_stay_x)
	_check("T5 切回后老鼠停留原地",
		_player.control_active and mouse_drift < 2.0,
		"drift=%.1f" % mouse_drift)

	# T6 窄缝通过性：16px 高通道，老鼠过、玩家不过
	var ceiling := StaticBody2D.new()
	var cshape := CollisionShape2D.new()
	var crect := RectangleShape2D.new()
	crect.size = Vector2(64, 32)
	cshape.shape = crect
	ceiling.add_child(cshape)
	ceiling.position = Vector2(700, SURFACE_Y - 16 - 16)
	add_child(ceiling)
	_player.position = Vector2(600, SURFACE_Y - 10)
	_player.velocity = Vector2.ZERO
	_mouse().position = Vector2(600, SURFACE_Y - 3)
	await _physics_frames(30)
	Input.action_press(&"move_right")
	await _physics_frames(120)
	Input.action_release(&"move_right")
	var player_blocked := _player.position.x < 694.0
	# 玩家挪走，再给老鼠让出通道
	_player.position = Vector2(500, SURFACE_Y - 10)
	_player.velocity = Vector2.ZERO
	_mouse().position = Vector2(600, SURFACE_Y - 3)
	await _physics_frames(10)
	# 换老鼠过
	await _tap(&"switch_control")
	await _physics_frames(3)
	Input.action_press(&"move_right")
	await _physics_frames(120)
	Input.action_release(&"move_right")
	var mouse_passed := _mouse().position.x > 740.0 # 通道出口 732 + 余量
	_check("T6 窄缝：玩家被挡/老鼠通过", player_blocked and mouse_passed,
		"player_x=%.1f mouse_x=%.1f" % [_player.position.x, _mouse().position.x])
	await _tap(&"switch_control")

	# T7 输入延迟 0.8s：按下后 0.4s 无响应，1.0s 后满速
	_mouse().input_delay = 0.8
	await _tap(&"switch_control") # 切到老鼠
	await _physics_frames(3)
	# 先静置 1.6s 清空输入历史（缓冲回放的是真实历史，测试需干净起点）
	await _physics_frames(100)
	Input.action_press(&"move_right")
	await _physics_frames(24) # 0.4s
	var early_v := absf(_mouse().velocity.x)
	await _physics_frames(42) # 累计约 1.1s
	var late_v := absf(_mouse().velocity.x)
	Input.action_release(&"move_right")
	_check("T7 0.8s 输入延迟生效", early_v < 5.0 and late_v > 40.0,
		"early=%.1f late=%.1f" % [early_v, late_v])
	_mouse().input_delay = 0.0
	await _tap(&"switch_control") # 切回玩家

	# T8 小型压力板权限：玩家踩不触发，老鼠踩触发
	var plate := (load("res://scenes/interactables/pressure_plate.tscn") as PackedScene).instantiate() as Area2D
	plate.position = Vector2(1200, SURFACE_Y - 2)
	plate.set("target_id", &"plate_a")
	plate.set("mouse_only", true)
	add_child(plate)
	await _physics_frames(3)
	_player.position = Vector2(1200, SURFACE_Y - 10)
	_player.velocity = Vector2.ZERO
	await _physics_frames(30)
	var by_player := MechanismBus.is_triggered(&"plate_a")
	_mouse().position = Vector2(1200, SURFACE_Y - 3)
	await _physics_frames(30)
	var by_mouse := MechanismBus.is_triggered(&"plate_a")
	_check("T8 小型板仅老鼠可踩", not by_player and by_mouse,
		"player=%s mouse=%s" % [by_player, by_mouse])
	_mouse().position = Vector2(600, SURFACE_Y - 3)
	await _physics_frames(10)

	# T9 大型板人鼠皆可（验证玩家即可）
	var big := (load("res://scenes/interactables/pressure_plate.tscn") as PackedScene).instantiate() as Area2D
	big.position = Vector2(1400, SURFACE_Y - 2)
	big.set("target_id", &"plate_b")
	big.set("mouse_only", false)
	add_child(big)
	await _physics_frames(3)
	_player.position = Vector2(1400, SURFACE_Y - 10)
	_player.velocity = Vector2.ZERO
	await _physics_frames(30)
	_check("T9 大型板玩家可踩", MechanismBus.is_triggered(&"plate_b"), "")

	# T10 老鼠死亡→5s 冷却→可再召唤
	var spikes := (load("res://scenes/interactables/spikes.tscn") as PackedScene).instantiate() as Area2D
	spikes.position = Vector2(600, SURFACE_Y - 8)
	add_child(spikes)
	# 同一帧内位移，避免老鼠先被刺死后访问空引用
	_mouse().position = Vector2(600, SURFACE_Y - 3)
	await _physics_frames(10)
	var gone := not ControlManager.is_mouse_out()
	await _tap(&"whistle")
	await _physics_frames(3)
	var blocked := not ControlManager.is_mouse_out()
	await _physics_frames(300) # 5s
	await _tap(&"whistle")
	await _physics_frames(3)
	_check("T10 死亡冷却 5s 后可再召唤", gone and blocked and ControlManager.is_mouse_out(),
		"gone=%s blocked=%s out=%s" % [gone, blocked, ControlManager.is_mouse_out()])

	# T11 收回：在场时按 Q 消失
	await _tap(&"whistle")
	await _physics_frames(3)
	_check("T11 Q 收回老鼠", not ControlManager.is_mouse_out(), "")

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
