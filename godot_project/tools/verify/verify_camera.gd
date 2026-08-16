extends SceneTree
## M1 相机跟随断言（Phantom Camera 接管后）。
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
	await physics_frame
	# 等玩家落地、相机收敛（带 0.15s 阻尼），跑 3 秒
	for i in range(180):
		await physics_frame

	var camera := root.get_node("RoomBase/Camera2D") as Camera2D
	var player := root.get_node("RoomBase/Characters/Player") as CharacterBody2D
	var host := root.get_node("RoomBase/Camera2D/PhantomCameraHost") as Node

	var has_active_pcam: bool = host.get("_active_pcam_2d") != null

	var cam_pos: Vector2 = camera.global_position
	var player_pos: Vector2 = player.global_position
	var dist := cam_pos.distance_to(player_pos)

	_check("相机已由 PhantomCamera 接管", has_active_pcam, "active_pcam_2d 为空")
	_check(
		"相机收敛到玩家（±6px）",
		dist <= 6.0,
		"cam=%.1f,%.1f player=%.1f,%.1f dist=%.1f" % [cam_pos.x, cam_pos.y, player_pos.x, player_pos.y, dist]
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
