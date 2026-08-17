extends Node
## M7 Boss AI 自动断言：五状态全部转换路径、老鼠优先级、双扑杀、搜索 10s 超时、环境光暴露。
## 转换条件依据策划案 §二(四)2/3。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_boss.gd

const SURFACE_Y := 384.0
const SPAWN := Vector2(160, SURFACE_Y - 10.0)
const SPAWN_MARK := Vector2(64, SURFACE_Y - 10.0)
# Boss 站立时中心在地表上方 48px（判定 96×96）
const BOSS_Y := SURFACE_Y - 48.0

var _player: CharacterBody2D
var _lamp: Node2D
var _boss: Boss
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
	spawn.position = SPAWN_MARK
	add_child(spawn)

	_player = (load("res://scenes/characters/player.tscn") as PackedScene).instantiate()
	_player.position = SPAWN
	add_child(_player)
	_lamp = _player.get_node("Lamp")
	GameState.has_lamp = true

	_boss = (load("res://scenes/characters/boss.tscn") as PackedScene).instantiate() as Boss
	_boss.patrol_half_extent_tiles = 2.0 # 缩短巡逻幅度，避免游走干扰断言
	_boss.position = Vector2(800, BOSS_Y)
	add_child(_boss)
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


## 等待 Boss 进入目标状态，超帧数未到达返回 false
func _wait_state(target: Boss.State, max_frames: int) -> bool:
	for i in range(max_frames):
		await get_tree().physics_frame
		if _boss.get_state() == target:
			return true
	return false


func _boss_state() -> String:
	return _boss.get_state_name()


func _reset_player() -> void:
	_player.global_position = SPAWN
	_player.velocity = Vector2.ZERO
	_player.reset_physics_interpolation()


func _spawn_mouse(pos: Vector2) -> Mouse:
	var mouse := (load("res://scenes/characters/mouse.tscn") as PackedScene).instantiate() as Mouse
	mouse.position = pos
	add_child(mouse)
	ControlManager.mouse = mouse
	return mouse


func _free_mouse() -> void:
	if ControlManager.mouse != null:
		ControlManager.mouse.queue_free()
		ControlManager.mouse = null


func _run_tests() -> void:
	await _physics_frames(10) # 落地 + Autoload 注册

	# T1 巡逻：关灯且距离远，Boss 保持巡逻并来回移动
	var start_x: float = _boss.global_position.x
	var max_dev := 0.0
	for i in range(240):
		await get_tree().physics_frame
		max_dev = maxf(max_dev, absf(_boss.global_position.x - start_x))
	_check("T1 无光源保持巡逻并游走", _boss.get_state() == Boss.State.PATROL and max_dev > 10.0,
		"state=%s dev=%.1f" % [_boss_state(), max_dev])

	# T2 警戒：开灯、距离 10 格（>8 格追击线）→ ALERT
	_lamp.call("set_lamp_on", true)
	_boss.reset_to_patrol(Vector2(SPAWN.x + 160.0, BOSS_Y))
	await _physics_frames(5)
	var alerted := await _wait_state(Boss.State.ALERT, 30)
	_check("T2 光源 >8 格进入警戒", alerted, "state=%s" % _boss_state())

	# T3 追击：距离 6 格（≤8 格）→ CHASE
	_boss.reset_to_patrol(Vector2(SPAWN.x + 96.0, BOSS_Y))
	await _physics_frames(5)
	var chasing := await _wait_state(Boss.State.CHASE, 30)
	_check("T3 光源 ≤8 格进入追击", chasing, "state=%s" % _boss_state())

	# T4 追击目标消失（关灯）→ SEARCH
	_lamp.call("set_lamp_on", false)
	var searching := await _wait_state(Boss.State.SEARCH, 15)
	_check("T4 目标消失转搜索", searching, "state=%s" % _boss_state())

	# T5 搜索 10s 超时回巡逻（真实时长，600 帧）
	var back_patrol := await _wait_state(Boss.State.PATROL, 640)
	_check("T5 搜索 10s 超时回巡逻", back_patrol, "state=%s" % _boss_state())

	# T6 分心优先：玩家开灯在追击距离内，老鼠更近（5 格）→ DISTRACTED
	_lamp.call("set_lamp_on", true)
	_boss.reset_to_patrol(Vector2(SPAWN.x + 96.0, BOSS_Y))
	await _physics_frames(5)
	await _wait_state(Boss.State.CHASE, 30)
	_spawn_mouse(Vector2(_boss.global_position.x - 80.0, SURFACE_Y - 3.0))
	var distracted := await _wait_state(Boss.State.DISTRACTED, 30)
	_check("T6 老鼠 ≤6 格优先分心", distracted, "state=%s" % _boss_state())

	# T7 捕获老鼠：Boss 分心追上静止老鼠 → 老鼠消失、5s 冷却、Boss 转搜索
	var caught := await _wait_state(Boss.State.SEARCH, 120)
	_check("T7 捕获老鼠：消失+冷却+转搜索",
		caught and ControlManager.mouse == null and ControlManager.get_cooldown() > 3.0,
		"state=%s mouse=%s cd=%.2f" % [_boss_state(), ControlManager.mouse, ControlManager.get_cooldown()])

	# T8 老鼠脱离：分心追老鼠时老鼠瞬移到 6 格外 → 搜索
	_lamp.call("set_lamp_on", true)
	_boss.reset_to_patrol(Vector2(SPAWN.x + 96.0, BOSS_Y))
	await _physics_frames(5)
	await _wait_state(Boss.State.CHASE, 30)
	var mouse := _spawn_mouse(Vector2(_boss.global_position.x - 80.0, SURFACE_Y - 3.0))
	await _wait_state(Boss.State.DISTRACTED, 30)
	mouse.global_position = Vector2(_boss.global_position.x - 240.0, SURFACE_Y - 3.0) # 15 格，远超 6 格
	var lost_mouse := await _wait_state(Boss.State.SEARCH, 30)
	_check("T8 老鼠脱离范围转搜索", lost_mouse, "state=%s" % _boss_state())
	_free_mouse()

	# T9 扑杀玩家：追击接触 → 玩家回出生点（标记在 SPAWN_MARK）
	_boss.reset_to_patrol(Vector2(SPAWN.x + 96.0, BOSS_Y))
	await _physics_frames(5)
	await _wait_state(Boss.State.CHASE, 30)
	var killed := false
	for i in range(120):
		await get_tree().physics_frame
		if _player.global_position.distance_to(SPAWN_MARK) < 8.0:
			killed = true
			break
	_check("T9 接触扑杀玩家回出生点", killed, "player=%s" % _player.global_position)
	_lamp.call("set_lamp_on", false)
	_reset_player()

	# T10 黑暗安全：关灯、Boss 近在咫尺（4 格）也保持巡逻
	_boss.reset_to_patrol(Vector2(SPAWN.x + 64.0, BOSS_Y))
	await _physics_frames(60)
	_check("T10 关灯黑暗中不攻击", _boss.get_state() == Boss.State.PATROL,
		"state=%s" % _boss_state())

	# T11 环境光暴露：关灯但站在环境光内（≤8 格）→ 追击
	var env := (load("res://scenes/interactables/ambient_light.tscn") as PackedScene).instantiate() as Node2D
	env.set("radius_tiles", 4.0)
	env.position = SPAWN
	add_child(env)
	_boss.reset_to_patrol(Vector2(SPAWN.x + 96.0, BOSS_Y))
	await _physics_frames(5)
	var env_chase := await _wait_state(Boss.State.CHASE, 30)
	_check("T11 环境光暴露被追击", env_chase, "state=%s" % _boss_state())
	env.queue_free()
	_boss.reset_to_patrol(Vector2(800, BOSS_Y))

	# T12 警戒中光源消失 → 回巡逻
	_lamp.call("set_lamp_on", true)
	_boss.reset_to_patrol(Vector2(SPAWN.x + 160.0, BOSS_Y))
	await _physics_frames(5)
	await _wait_state(Boss.State.ALERT, 30)
	_lamp.call("set_lamp_on", false)
	var alert_gone := await _wait_state(Boss.State.PATROL, 30)
	_check("T12 警戒中光源消失回巡逻", alert_gone, "state=%s" % _boss_state())

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
