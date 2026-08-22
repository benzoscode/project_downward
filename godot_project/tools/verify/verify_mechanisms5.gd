extends Node
## 2026-08-20 新积木验证：三宝石门（镶嵌/全开/持久化）+ 呼吸灯（亮灭/配色）。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_mechanisms5.gd

const SURFACE_Y := 384.0

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


func _spawn_set(path: String, pos: Vector2, props: Dictionary) -> Node2D:
	var node := (load(path) as PackedScene).instantiate() as Node2D
	node.position = pos
	for k in props:
		node.set(k, props[k])
	add_child(node)
	return node


func _physics_frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


func _socket_tex(gate: Node2D, name: String) -> String:
	var sprite := gate.get_node("Sockets/" + name) as Sprite2D
	return sprite.texture.resource_path


func _run_tests() -> void:
	MechanismBus.reset_all()
	GameState.gems.clear()
	await _physics_frames(10)

	# ---- T1 三宝石门：逐颗镶嵌（先给埃、嵌入；再补琥珀；再补紫金 → 全开），无宝石无效 ----
	var gate := _spawn_set("res://scenes/interactables/gem_gate.tscn", Vector2(400, SURFACE_Y - 24),
		{"gate_id": &"gate_t1"})
	await _physics_frames(3)
	# 无宝石：无效
	GameState.gems = []
	gate.call("interact")
	await _physics_frames(5)
	var no_open: bool = not gate.call("is_open")
	# 给翡翠 → 镶嵌
	GameState.gems.append(&"gem_jade")
	gate.call("interact")
	await _physics_frames(5)
	var jade_only: bool = not gate.call("is_open")
	# 补琥珀、紫金 → 全开
	GameState.gems.append(&"gem_amber")
	gate.call("interact")
	GameState.gems.append(&"gem_violet")
	gate.call("interact")
	await _physics_frames(40)
	var opened: bool = gate.call("is_open")
	var collision_off: bool = (gate.get_node("CollisionShape2D") as CollisionShape2D).disabled
	var consumed: bool = GameState.gems.is_empty()
	_check("T1 三宝石门镶嵌并全开", no_open and jade_only and opened and collision_off and consumed,
		"no=%s jade=%s open=%s colOff=%s gems=%s" % [no_open, jade_only, opened, collision_off, GameState.gems])
	gate.queue_free()
	await _physics_frames(10)

	# ---- T2 三宝石门 socket 持久化：镶嵌一颗后新实例按总线复原 ----
	MechanismBus.reset_all()
	GameState.gems = [&"gem_jade"]
	var gate_a := _spawn_set("res://scenes/interactables/gem_gate.tscn", Vector2(700, SURFACE_Y - 24),
		{"gate_id": &"gate_t2"})
	await _physics_frames(3)
	gate_a.call("interact") # 镶嵌翡翠
	await _physics_frames(5)
	var gate_b := _spawn_set("res://scenes/interactables/gem_gate.tscn", Vector2(700, SURFACE_Y - 24),
		{"gate_id": &"gate_t2"})
	await _physics_frames(5)
	var jade_filled := _socket_tex(gate_b, "SocketJade") == "res://assets/props/door_gem_jade.png"
	var amber_empty := _socket_tex(gate_b, "SocketAmber") == "res://assets/props/door_gem_amber_empty.png"
	_check("T2 三宝石门 socket 持久化", jade_filled and amber_empty,
		"jade=%s amber=%s" % [_socket_tex(gate_b, "SocketJade"), _socket_tex(gate_b, "SocketAmber")])
	gate_a.queue_free()
	gate_b.queue_free()
	await _physics_frames(10)

	# ---- T3 呼吸灯：能量随周期在 [min,max] 间震荡 ----
	var light := _spawn("res://scenes/interactables/breathing_light.tscn", Vector2(200, SURFACE_Y - 40))
	light.set("min_energy", 0.3)
	light.set("max_energy", 1.8)
	light.set("period", 3.0)
	light.set("light_color", Color(1.0, 0.5, 0.3))
	await _physics_frames(5)
	var l2d: PointLight2D = light.get_node("PointLight2D")
	var lo := 999.0
	var hi := -1.0
	for i in range(90): # 1.5s，应覆盖半个周期
		await get_tree().physics_frame
		lo = minf(lo, l2d.energy)
		hi = maxf(hi, l2d.energy)
	var oscillates := (hi - lo) > 0.5 and lo >= 0.29 and hi <= 1.81
	var color_ok: bool = l2d.color.is_equal_approx(Color(1.0, 0.5, 0.3))
	_check("T3 呼吸灯震荡且配色生效", oscillates and color_ok,
		"lo=%.2f hi=%.2f color=%s" % [lo, hi, l2d.color])
	light.queue_free()

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
