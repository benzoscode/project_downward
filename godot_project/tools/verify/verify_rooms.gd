extends Node
## M8 房间连通自动断言：
## 静态——12 房间出口连线 BFS 全可达、目标入口标记存在、能力门结构（二段跳高墙/老鼠窄缝）；
## 运行——过渡落位与检查点、出口触发区真实切换、死亡同房间/跨房间重生、钥匙门拦截放行、pcam 钳制同步。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_rooms.gd

const EXIT_SCRIPT := "res://scripts/interactables/room_exit.gd"
const KEY_DOOR_SCRIPT := "res://scripts/interactables/key_door.gd"

var _failures: int = 0
var _passed: int = 0


func _ready() -> void:
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


## 加载房间并提取出口连线（不挂树，避免触发 RoomBase 注册）
func _scan_room_exits(room_id: StringName) -> Array[Dictionary]:
	var packed := load(RoomManager.ROOMS[room_id]) as PackedScene
	var room := packed.instantiate()
	var exits: Array[Dictionary] = []
	_collect_exits(room, exits)
	room.free()
	return exits


func _collect_exits(node: Node, out: Array[Dictionary]) -> void:
	if node.get_script() != null and (node.get_script() as Script).resource_path == EXIT_SCRIPT:
		out.append({
			"target_room": node.get("target_room"),
			"target_entrance": node.get("target_entrance"),
		})
	for child in node.get_children():
		_collect_exits(child, out)


func _has_entrance(room_id: StringName, entrance: StringName) -> bool:
	var packed := load(RoomManager.ROOMS[room_id]) as PackedScene
	var room := packed.instantiate()
	var found := room.get_node_or_null("Entrance_" + String(entrance)) != null
	if not found and entrance != &"default":
		found = room.get_node_or_null("Entrance_default") != null
	if not found:
		found = room.get_node_or_null("SpawnPoint") != null
	room.free()
	return found


func _terrain_solid(room_id: StringName, cell: Vector2i) -> bool:
	var packed := load(RoomManager.ROOMS[room_id]) as PackedScene
	var room := packed.instantiate()
	var terrain := room.get_node("TileMapTerrain") as TileMapLayer
	var solid := terrain.get_cell_source_id(cell) != -1
	room.free()
	return solid


## 等房间切换完成：按真实时间超时（headless 无垂直同步，帧跑得快、补间按秒走，数帧不可靠）
func _wait_room(room_id: StringName, timeout_ms: int = 8000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		if RoomManager.current_room_id == room_id and not RoomManager.is_transitioning():
			return true
		await get_tree().process_frame
	return false


func _run_tests() -> void:
	MechanismBus.reset_all()

	# ---- T1 连通性：BFS 从 room_01 出发 12 房间全可达，且每条连线目标入口存在 ----
	var graph := {}
	var missing_entrance := ""
	var unregistered := ""
	for room_id in RoomManager.ROOMS:
		var exits := _scan_room_exits(room_id)
		graph[room_id] = exits
		for exit in exits:
			if not RoomManager.ROOMS.has(exit["target_room"]):
				unregistered += "%s→%s " % [room_id, exit["target_room"]]
			elif not _has_entrance(exit["target_room"], exit["target_entrance"]):
				missing_entrance += "%s→%s:%s " % [room_id, exit["target_room"], exit["target_entrance"]]
	var visited := {&"room_01": true}
	var queue: Array[StringName] = [&"room_01"]
	while not queue.is_empty():
		var cur: StringName = queue.pop_front()
		for exit in graph.get(cur, []):
			var nxt: StringName = exit["target_room"]
			if not visited.has(nxt):
				visited[nxt] = true
				queue.append(nxt)
	_check("T1a 12 房间连通（BFS 全可达）", visited.size() == 12,
		"visited=%d missing=%s" % [visited.size(), RoomManager.ROOMS.keys().filter(func(r): return not visited.has(r))])
	_check("T1b 出口目标均已注册且入口标记存在", unregistered.is_empty() and missing_entrance.is_empty(),
		"unregistered=%s missing=%s" % [unregistered, missing_entrance])

	# ---- T2 能力门结构（静态）：room_03 五格高墙（行 8..12）、room_09 老鼠窄缝（行 12 通行）----
	var wall_solid := true
	for y in range(8, 13):
		wall_solid = wall_solid and _terrain_solid(&"room_03", Vector2i(12, y))
	_check("T2a 二段跳高墙（5 格实心）", wall_solid and not _terrain_solid(&"room_03", Vector2i(12, 7)))
	var gap_ok := not _terrain_solid(&"room_09", Vector2i(20, 12))
	for y in range(8, 12):
		gap_ok = gap_ok and _terrain_solid(&"room_09", Vector2i(20, y))
	_check("T2b 老鼠窄缝（底行 1 格高通道）", gap_ok)

	# ---- T3 过渡与检查点（运行）----
	RoomManager.goto_room(&"room_01", &"default")
	var ok := await _wait_room(&"room_01")
	var player := get_tree().get_first_node_in_group(&"player") as Player
	var entrance1 := (RoomManager.get_active_room().get_node("Entrance_default") as Marker2D).global_position
	_check("T3a 初始进 room_01 并落位入口", ok and player != null and player.global_position.distance_to(entrance1) < 8.0,
		"room=%s player=%s expect=%s" % [RoomManager.current_room_id, player.global_position if player else "null", entrance1])
	_check("T3b 检查点已记录 room_01", GameState.checkpoint_room == &"room_01",
		"checkpoint=%s" % GameState.checkpoint_room)

	RoomManager.goto_room(&"room_02", &"default")
	ok = await _wait_room(&"room_02")
	player = get_tree().get_first_node_in_group(&"player") as Player
	var entrance2 := (RoomManager.get_active_room().get_node("Entrance_default") as Marker2D).global_position
	_check("T3c 切换 room_02 落位+检查点更新",
		ok and player.global_position.distance_to(entrance2) < 8.0 and GameState.checkpoint_room == &"room_02",
		"room=%s checkpoint=%s" % [RoomManager.current_room_id, GameState.checkpoint_room])

	# ---- T4 pcam 钳制同步（遗留修复验证）：room_01 限 640（40 格），room_12 限 1440（90 格）----
	var pcam := player.get_node("PhantomCamera2D")
	var limit_r1: int = pcam.get("limit_right")
	RoomManager.goto_room(&"room_12", &"default")
	ok = await _wait_room(&"room_12")
	var limit_r12: int = pcam.get("limit_right")
	_check("T4 相机钳制随房间同步", limit_r1 == 640 and limit_r12 == 1440,
		"room_01=%d room_12=%d" % [limit_r1, limit_r12])

	# ---- T5 出口触发区真实切换：回 room_01 把玩家放上出口 ----
	RoomManager.goto_room(&"room_01", &"default")
	await _wait_room(&"room_01")
	player = get_tree().get_first_node_in_group(&"player") as Player
	var exit_node := RoomManager.get_active_room().get_node("Exit_to_room_02") as Area2D
	player.global_position = exit_node.global_position
	player.reset_physics_interpolation()
	ok = await _wait_room(&"room_02")
	_check("T5 踩出口触发区切换到 room_02", ok, "room=%s" % RoomManager.current_room_id)

	# ---- T6 死亡重生：同房间回检查点 ----
	player = get_tree().get_first_node_in_group(&"player") as Player
	var cp := GameState.checkpoint_position
	player.global_position = cp + Vector2(200, 0)
	await _physics_frames(5)
	player.die()
	await _physics_frames(10)
	_check("T6 同房间死亡回检查点",
		RoomManager.current_room_id == &"room_02" and player.global_position.distance_to(cp) < 8.0,
		"room=%s pos=%s expect=%s" % [RoomManager.current_room_id, player.global_position, cp])

	# ---- T7 死亡重生：跨房间（检查点在 room_02，死在 room_03）----
	RoomManager.goto_room(&"room_03", &"default")
	await _wait_room(&"room_03")
	player = get_tree().get_first_node_in_group(&"player") as Player
	# 手动把检查点设回 room_02（模拟之前在 room_02 存过档，当前房间死亡）
	GameState.set_checkpoint(&"room_02", cp)
	player.die()
	ok = await _wait_room(&"room_02")
	player = get_tree().get_first_node_in_group(&"player") as Player
	_check("T7 跨房间死亡回检查点房间", ok and player.global_position.distance_to(cp) < 8.0,
		"room=%s pos=%s expect=%s" % [RoomManager.current_room_id, player.global_position, cp])

	# ---- T8 钥匙门拦截/放行 ----
	GameState.has_key = false
	var kd_packed := load("res://scenes/interactables/key_door.tscn") as PackedScene
	var kd := kd_packed.instantiate()
	add_child(kd)
	await _physics_frames(5)
	var blocked: bool = not kd.call("is_open")
	GameState.acquire_item(&"key")
	await _physics_frames(30) # 开门动画 0.6s
	var opened: bool = kd.call("is_open")
	_check("T8 钥匙门：无钥关闭/有钥开启", blocked and opened,
		"blocked=%s opened=%s" % [blocked, opened])
	kd.queue_free()

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
