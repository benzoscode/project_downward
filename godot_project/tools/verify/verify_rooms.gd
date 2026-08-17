extends Node
## M8 房间连通自动断言（方案 D 路径制）。
## 静态部分**自适应**：策划正在搭房间，房间可能缺失/未接入——断链（出口指到不存在的文件）
## 和入口缺失算失败；未接入 room_01 主图的房间只报 [INFO]（WIP 期间不算错）。
## 运行部分用专用样例房间（scenes/test/verify_room_a/b.tscn），与策划的在建房间完全解耦。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_rooms.gd

const EXIT_SCRIPT := "res://scripts/interactables/room_exit.gd"
const ROOM_DIR := "res://scenes/rooms/"
const RA := "res://scenes/test/verify_room_a.tscn"
const RB := "res://scenes/test/verify_room_b.tscn"
const R03 := ROOM_DIR + "room_03.tscn"
const R09 := ROOM_DIR + "room_09.tscn"

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


func _skip(test_name: String, reason: String) -> void:
	print("[SKIP] ", test_name, "（", reason, "）")


func _physics_frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


## 目录内全部房间场景路径（room_*.tscn）
func _list_rooms() -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(ROOM_DIR):
		if f.begins_with("room_") and f.ends_with(".tscn"):
			out.append(ROOM_DIR + f)
	out.sort()
	return out


## 加载房间并提取出口连线（不挂树，避免触发 RoomBase 注册）
func _scan_room_exits(scene_path: String) -> Array[Dictionary]:
	var packed := load(scene_path) as PackedScene
	var room := packed.instantiate()
	var exits: Array[Dictionary] = []
	_collect_exits(room, exits)
	room.free()
	return exits


func _collect_exits(node: Node, out: Array[Dictionary]) -> void:
	if node.get_script() != null and (node.get_script() as Script).resource_path == EXIT_SCRIPT:
		out.append({
			"target_scene": node.get("target_scene"),
			"target_entrance": node.get("target_entrance"),
		})
	for child in node.get_children():
		_collect_exits(child, out)


func _has_entrance(scene_path: String, entrance: StringName) -> bool:
	var packed := load(scene_path) as PackedScene
	var room := packed.instantiate()
	var found := room.get_node_or_null("Entrance_" + String(entrance)) != null
	if not found and entrance != &"default":
		found = room.get_node_or_null("Entrance_default") != null
	if not found:
		found = room.get_node_or_null("SpawnPoint") != null
	room.free()
	return found


func _terrain_solid(scene_path: String, cell: Vector2i) -> bool:
	var packed := load(scene_path) as PackedScene
	var room := packed.instantiate()
	var terrain := room.get_node("TileMapTerrain") as TileMapLayer
	var solid := terrain.get_cell_source_id(cell) != -1
	room.free()
	return solid


## 等房间切换完成：按真实时间超时（headless 无垂直同步，帧跑得快、补间按秒走，数帧不可靠）
func _wait_room(scene_path: String, timeout_ms: int = 8000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		if RoomManager.current_room_id == scene_path and not RoomManager.is_transitioning():
			return true
		await get_tree().process_frame
	return false


func _run_tests() -> void:
	MechanismBus.reset_all()

	# ---- T1 连通性（自适应）：出口目标文件存在 + 入口标记存在；未接入主图的房间只报 INFO ----
	var rooms := _list_rooms()
	var graph := {}
	var bad_target := ""
	var missing_entrance := ""
	for path in rooms:
		var exits := _scan_room_exits(path)
		graph[path] = exits
		for exit in exits:
			if not ResourceLoader.exists(exit["target_scene"]):
				bad_target += "%s→%s " % [path.get_file(), exit["target_scene"]]
			elif not _has_entrance(exit["target_scene"], exit["target_entrance"]):
				missing_entrance += "%s→%s:%s " % [path.get_file(), exit["target_scene"].get_file(), exit["target_entrance"]]
	_check("T1a 出口目标文件均存在（无断链）", bad_target.is_empty(), "bad=%s" % bad_target)
	_check("T1b 出口目标入口标记均存在", missing_entrance.is_empty(), "missing=%s" % missing_entrance)
	var start := ROOM_DIR + "room_01.tscn"
	if rooms.has(start):
		var visited := {start: true}
		var queue: Array[String] = [start]
		while not queue.is_empty():
			var cur: String = queue.pop_front()
			for exit in graph.get(cur, []):
				var nxt: String = exit["target_scene"]
				if graph.has(nxt) and not visited.has(nxt):
					visited[nxt] = true
					queue.append(nxt)
		var unlinked: Array[String] = []
		for r in rooms:
			if not visited.has(r):
				unlinked.append(r.get_file())
		print("[INFO] 主图可达 %d/%d 个房间；未接入：%s" % [visited.size(), rooms.size(), ", ".join(unlinked)])
	else:
		print("[INFO] room_01 不存在（WIP），跳过主图可达性统计")

	# ---- T2 能力门结构（静态；房间被策划拿走装修则跳过）----
	if ResourceLoader.exists(R03) and ResourceLoader.exists(R09):
		var wall_solid := true
		for y in range(8, 13):
			wall_solid = wall_solid and _terrain_solid(R03, Vector2i(12, y))
		_check("T2a 二段跳高墙（5 格实心）", wall_solid and not _terrain_solid(R03, Vector2i(12, 7)))
		var gap_ok := not _terrain_solid(R09, Vector2i(20, 12))
		for y in range(8, 12):
			gap_ok = gap_ok and _terrain_solid(R09, Vector2i(20, y))
		_check("T2b 老鼠窄缝（底行 1 格高通道）", gap_ok)
	else:
		_skip("T2 能力门结构", "room_03/room_09 装修中")

	# ---- T3 过渡与检查点（样例房间 A/B）----
	RoomManager.goto_room(RA, &"default")
	var ok := await _wait_room(RA)
	var player := get_tree().get_first_node_in_group(&"player") as Player
	var entrance_a := (RoomManager.get_active_room().get_node("Entrance_default") as Marker2D).global_position
	_check("T3a 初始进样例 A 并落位入口", ok and player != null and player.global_position.distance_to(entrance_a) < 8.0,
		"room=%s player=%s expect=%s" % [RoomManager.current_room_id, player.global_position if player else "null", entrance_a])
	_check("T3b 检查点已记录样例 A", GameState.checkpoint_room == RA,
		"checkpoint=%s" % GameState.checkpoint_room)

	RoomManager.goto_room(RB, &"default")
	ok = await _wait_room(RB)
	player = get_tree().get_first_node_in_group(&"player") as Player
	var entrance_b := (RoomManager.get_active_room().get_node("Entrance_default") as Marker2D).global_position
	_check("T3c 切换样例 B 落位+检查点更新",
		ok and player.global_position.distance_to(entrance_b) < 8.0 and GameState.checkpoint_room == RB,
		"room=%s checkpoint=%s" % [RoomManager.current_room_id, GameState.checkpoint_room])

	# ---- T3d 相机瞬移：进房间后镜头直接对准（钳制位），不做阻尼摇镜 ----
	# 样例 B 限幅 1440×272：视口半宽 240/半高 135，入口 (56,192) → 钳制位 (240, 272-135=137)
	var camb := RoomManager.get_active_room().get_node("Camera2D") as Camera2D
	var expect_cam := Vector2(240, 137)
	_check("T3d 进房间相机瞬移到钳制位", camb.global_position.distance_to(expect_cam) < 4.0,
		"cam=%s expect=%s" % [camb.global_position, expect_cam])

	# ---- T4 pcam 钳制同步：A 限 640，B 限 1440 ----
	var pcam := player.get_node("PhantomCamera2D")
	var limit_rb: int = pcam.get("limit_right")
	RoomManager.goto_room(RA, &"default")
	ok = await _wait_room(RA)
	var limit_ra: int = pcam.get("limit_right")
	_check("T4 相机钳制随房间同步", limit_ra == 640 and limit_rb == 1440,
		"A=%d B=%d" % [limit_ra, limit_rb])

	# ---- T5 出口触发区真实切换：把玩家放上 A 的出口 ----
	player = get_tree().get_first_node_in_group(&"player") as Player
	var exit_node := RoomManager.get_active_room().get_node("Exit_to_b") as Area2D
	player.global_position = exit_node.global_position
	player.reset_physics_interpolation()
	ok = await _wait_room(RB)
	_check("T5 踩出口触发区切换到样例 B", ok, "room=%s" % RoomManager.current_room_id)

	# ---- T6 死亡重生：同房间回检查点 ----
	player = get_tree().get_first_node_in_group(&"player") as Player
	var cp := GameState.checkpoint_position
	player.global_position = cp + Vector2(200, 0)
	await _physics_frames(5)
	player.die()
	await _physics_frames(10)
	_check("T6 同房间死亡回检查点",
		RoomManager.current_room_id == RB and player.global_position.distance_to(cp) < 8.0,
		"room=%s pos=%s expect=%s" % [RoomManager.current_room_id, player.global_position, cp])

	# ---- T7 死亡重生：跨房间（检查点在 A，死在 B）----
	GameState.set_checkpoint(RA, cp)
	player.die()
	ok = await _wait_room(RA)
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

	# ---- T9 检查点积木：触碰存档、死亡回积木位置 ----
	RoomManager.goto_room(RB, &"default")
	await _wait_room(RB)
	player = get_tree().get_first_node_in_group(&"player") as Player
	var ck := (load("res://scenes/interactables/checkpoint.tscn") as PackedScene).instantiate() as Area2D
	var room := RoomManager.get_active_room()
	var ck_pos := GameState.checkpoint_position + Vector2(96, 0)
	ck.position = ck_pos
	room.add_child(ck)
	await _physics_frames(5)
	player.global_position = ck_pos
	player.reset_physics_interpolation()
	await _physics_frames(10)
	var saved := GameState.checkpoint_position.distance_to(ck_pos) < 4.0
	player.global_position = ck_pos + Vector2(64, 0)
	await _physics_frames(3)
	player.die()
	await _physics_frames(10)
	_check("T9 检查点积木触碰存档+死亡回积木", saved and player.global_position.distance_to(ck_pos) < 8.0,
		"saved=%s pos=%s expect=%s" % [saved, player.global_position, ck_pos])

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
