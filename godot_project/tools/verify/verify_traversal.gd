extends Node
## M3 穿越与死亡自动断言：水体减速、梯子攀爬、地刺死亡重生、机关状态保留。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_traversal.gd

const SURFACE_Y := 384.0
const SPAWN := Vector2(80, SURFACE_Y - 10.0)

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

	# 出生点标记：死亡重生逻辑依赖此组
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

	# T1 水体减速：水中满速应为陆地 48px/s 的 0.5 倍（水域 x120..320）
	var water := _spawn("res://scenes/interactables/water.tscn", Vector2(120, SURFACE_Y - 48))
	water.set("size", Vector2i(200, 48))
	await _physics_frames(5)
	Input.action_press(&"move_right")
	# 先跑进水域深处再测速
	for i in range(300):
		await get_tree().physics_frame
		if _player.position.x > 180.0:
			break
	await _physics_frames(20)
	var water_speed := absf(_player.velocity.x)
	_check("T1 水中移速减半", water_speed >= 20.0 and water_speed <= 28.0,
		"水中速度=%.1f，期望 20~28" % water_speed)

	# T2 水域视觉：在水中精灵半透明，离开后恢复
	var alpha_in: float = (_player.get_node("AnimatedSprite2D") as CanvasItem).modulate.a
	for i in range(600):
		await get_tree().physics_frame
		if _player.position.x > 340.0:
			break
	Input.action_release(&"move_right")
	await _physics_frames(30)
	var alpha_out: float = (_player.get_node("AnimatedSprite2D") as CanvasItem).modulate.a
	_check("T2 水中半透明/离水恢复", alpha_in < 0.9 and alpha_out > 0.99,
		"in=%.2f out=%.2f" % [alpha_in, alpha_out])

	# T3 梯子攀爬：按住上持续升高
	_player.position = Vector2(600, SURFACE_Y - 10.0)
	_player.velocity = Vector2.ZERO
	_player.reset_physics_interpolation()
	var ladder := _spawn("res://scenes/interactables/ladder.tscn", Vector2(592, SURFACE_Y))
	ladder.set("height", 96)
	await _settle()
	await _physics_frames(5)
	var start_y := _player.position.y
	Input.action_press(&"move_up")
	await _physics_frames(60)
	var climbed := start_y - _player.position.y
	_check("T3 梯子持续爬升", climbed > 28.0,
		"60 帧爬升=%.1fpx，期望 >28（2格/秒）" % climbed)

	# T4 梯上跳：攀爬中按跳获得上升速度
	Input.action_release(&"move_up")
	await get_tree().physics_frame
	Input.action_press(&"move_up")
	await _physics_frames(8)
	Input.action_press(&"jump")
	await get_tree().physics_frame
	Input.action_release(&"jump")
	Input.action_release(&"move_up")
	await get_tree().physics_frame
	_check("T4 梯上跳出", _player.velocity.y < -150.0,
		"vy=%.1f，期望 <-150" % _player.velocity.y)
	ladder.queue_free()

	# T5 地刺致死重生 + T6 机关状态保留
	MechanismBus.trigger(&"persist_test")
	_player.position = SPAWN
	_player.velocity = Vector2.ZERO
	_player.reset_physics_interpolation()
	_spawn("res://scenes/interactables/spikes.tscn", Vector2(200, SURFACE_Y - 8))
	await _settle()
	Input.action_press(&"move_right")
	for i in range(90):
		await get_tree().physics_frame
		if _player.position.x < 120.0 and i > 10: # 已回出生点
			break
	Input.action_release(&"move_right")
	var back_home := _player.position.distance_to(SPAWN) < 8.0
	_check("T5 触刺重生回出生点", back_home,
		"pos=%s，期望 %s" % [_player.position, SPAWN])
	_check("T6 死后机关状态保留", MechanismBus.is_triggered(&"persist_test"),
		"persist_test=%s" % MechanismBus.is_triggered(&"persist_test"))

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
