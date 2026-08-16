extends Node
## M3 机关联动自动断言：按钮→总线→门、一次性按钮、拾取物、宝箱。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_mechanisms.gd

const SURFACE_Y := 384.0
const SPAWN := Vector2(160, SURFACE_Y - 10.0)

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


func _tap_interact() -> void:
	Input.action_press(&"interact")
	await get_tree().physics_frame
	Input.action_release(&"interact")
	await get_tree().physics_frame


func _run_tests() -> void:
	MechanismBus.reset_all()
	await _settle()

	# T1 按钮→门：E 触发后门在动画结束后打开
	var button := _spawn("res://scenes/interactables/lion_button.tscn", SPAWN + Vector2(16, 0))
	button.set("target_id", &"door_a")
	var door := _spawn("res://scenes/interactables/stone_door.tscn", Vector2(400, SURFACE_Y - 24))
	door.set("listen_id", &"door_a")
	await _physics_frames(2)
	await _tap_interact()
	await _physics_frames(40)
	_check("T1 按钮触发→门开", door.call("is_open") and MechanismBus.is_triggered(&"door_a"),
		"is_open=%s bus=%s" % [door.call("is_open"), MechanismBus.is_triggered(&"door_a")])

	# T2 可重复按钮：再按一次门关闭
	await _tap_interact()
	await _physics_frames(40)
	_check("T2 再按→门关（可重复）", not door.call("is_open") and not MechanismBus.is_triggered(&"door_a"),
		"is_open=%s" % door.call("is_open"))
	button.queue_free()
	door.queue_free()

	# T3 一次性按钮：第二次按不解除
	var one_shot := _spawn("res://scenes/interactables/lion_button.tscn", SPAWN + Vector2(16, 0))
	one_shot.set("target_id", &"door_b")
	one_shot.set("one_shot", true)
	await _physics_frames(2)
	await _tap_interact()
	await _tap_interact()
	_check("T3 一次性按钮不解除", MechanismBus.is_triggered(&"door_b"),
		"bus=%s" % MechanismBus.is_triggered(&"door_b"))
	one_shot.queue_free()

	# T4 拾取物：碰到即获得并消失
	var pickup := _spawn("res://scenes/interactables/pickup.tscn", SPAWN)
	pickup.set("item", &"boots")
	await _physics_frames(5)
	_check("T4 拾取物入账并消失", GameState.has_boots and not is_instance_valid(pickup),
		"has_boots=%s" % GameState.has_boots)

	# T5 宝箱：E 开启发道具
	var chest := _spawn("res://scenes/interactables/chest.tscn", SPAWN + Vector2(24, 0))
	chest.set("item", &"gem_jade")
	await _physics_frames(2)
	await _tap_interact()
	_check("T5 宝箱发道具", GameState.gems.has(&"gem_jade"),
		"gems=%s" % GameState.gems)

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
