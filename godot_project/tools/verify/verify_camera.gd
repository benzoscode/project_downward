extends SceneTree
## M1 相机跟随断言（Phantom Camera 接管后）。
## M8 起 pcam limit 生效（遗留修复）：贴底/贴边时相机按房间钳制停，不再无条件贴脸。
## 用法：godot --headless --script tools/verify/verify_camera.gd
## 通过退出码 0，失败退出码 1。

var _failed: int = 0
var _passed: int = 0


func _initialize() -> void:
	var scene := load("res://scenes/rooms/demo_room.tscn") as PackedScene
	var room := scene.instantiate()
	root.add_child(room)
	_run()


func _process(_delta: float) -> bool:
	return _done


var _done := false


func _run() -> void:
	var camera := root.get_node("RoomBase/Camera2D") as Camera2D
	var player := root.get_node("RoomBase/Characters/Player") as CharacterBody2D
	var host := root.get_node("RoomBase/Camera2D/PhantomCameraHost") as Node
	await physics_frame
	# 等 RoomBase 延迟注册完成（会把玩家放回出生点），再移动玩家
	for i in range(5):
		await physics_frame
	# 移到房间中部地面：水平远离左右边界可贴脸；垂直贴底（limit_bottom=1080）应钳在 945
	player.global_position = Vector2(960, 998)
	player.reset_physics_interpolation()
	# 等玩家落地、相机收敛（带 0.15s 阻尼），跑 3 秒
	for i in range(180):
		await physics_frame

	var has_active_pcam: bool = host.get("_active_pcam_2d") != null

	var cam_pos: Vector2 = camera.global_position
	var expect := Vector2(player.global_position.x, 945.0)
	var dist := cam_pos.distance_to(expect)
	_check("相机已由 PhantomCamera 接管", has_active_pcam, "active_pcam_2d 为空")
	_check(
		"相机跟随并受房间钳制（±6px）",
		dist <= 6.0,
		"cam=%.1f,%.1f expect=%.1f,%.1f dist=%.1f" % [cam_pos.x, cam_pos.y, expect.x, expect.y, dist]
	)

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failed])
	_done = true
	quit(1 if _failed > 0 else 0)


func _check(test_name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_passed += 1
		print("[PASS] ", test_name)
	else:
		_failed += 1
		printerr("[FAIL] ", test_name, " | ", detail)
