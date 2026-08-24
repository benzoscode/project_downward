extends Node
## 房间管理（Autoload: RoomManager，M8）
## 职责：房间切换（淡出/淡入）、入口落位、检查点重生、玩家实例跨房间托管。
## 协议（策划手册见 building_blocks.md）：
## - 房间根节点挂 RoomBase 脚本；运行时自动注册到本管理器（路径取自 scene_file_path）
## - 入口 = 房间内名为 `Entrance_<id>` 的 Marker2D（缺省 `Entrance_default`，再缺省 SpawnPoint）
## - 出口 = room_exit.tscn 积木，`target_scene` 在 Inspector 选 .tscn 文件 + `target_entrance`
## 死亡重生回最近检查点（进入房间的入口），机关状态由 MechanismBus 保留（策划案 §一）。

## 房间切换完成（新场景已就绪、玩家已落位）时发出
signal room_changed(scene_path: String)

const PLAYER_SCENE := "res://scenes/characters/player.tscn"

## 当前场景路径（.tscn）。M8 方案 D：无注册表，出口积木直接存场景路径
var current_room_id: String = ""

var _room: Node2D = null
var _player: Player = null
var _transitioning: bool = false
var _pending_entrance: StringName = &"default"
var _fade_rect: ColorRect = null


func _ready() -> void:
	# 过渡遮罩：常驻最上层，平时透明
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade_rect)


## 由 RoomBase 运行时注册（房间实例化并 add_child 后回调）。
## 独立运行的测试场景（demo_room/labs 自带玩家）也走这里——玩家已存在则被收养。
func register_active_room(room: Node2D) -> void:
	_room = room
	# 场景实例自带来源路径（scene_file_path），无需任何注册/配置
	current_room_id = room.scene_file_path
	_ensure_player()
	_place_player(_pending_entrance)
	_pending_entrance = &"default"
	_apply_room_camera_limits()
	GameState.current_room = current_room_id
	GameState.set_checkpoint(current_room_id, _player.global_position)
	room_changed.emit(current_room_id)


## 切换到目标场景的指定入口（带淡出/淡入）。过渡期间忽略重复触发。
func goto_room(target_scene: String, target_entrance: StringName = &"default") -> void:
	if _transitioning:
		return
	if not ResourceLoader.exists(target_scene):
		printerr("RoomManager: 场景不存在 ", target_scene)
		return
	_transitioning = true
	_lock_player(true)
	# 收回老鼠：跨房间不携带（主动转场免死亡冷却）
	ControlManager.force_recall()
	await _fade_to(1.0)
	# 黑场停留一拍：渐出/渐入节奏可被感知（用户反馈原 0.25s 直连看不出渐入）
	await get_tree().create_timer(0.15).timeout
	# 把持久玩家从旧房间摘下，避免随旧房间一起释放
	if _player != null and is_instance_valid(_player) and _player.get_parent() != null:
		_player.get_parent().remove_child(_player)
	if _room != null and is_instance_valid(_room):
		_room.queue_free()
	_pending_entrance = target_entrance
	var packed := load(target_scene) as PackedScene
	_room = packed.instantiate() as Node2D
	get_tree().root.add_child(_room)
	# RoomBase._ready 回调 register_active_room 完成落位与检查点
	await get_tree().process_frame
	await get_tree().process_frame
	_lock_player(false)
	await _fade_to(0.0)
	_transitioning = false


## 退出到独立 UI 场景（结局/菜单）。RoomManager 把房间挂在 root（current_scene 为空 Main），
## 直接 change_scene_to_file 只释放 current_scene、不会清掉房间，故需先在此清理房间与玩家。
func exit_to_scene(scene_path: String) -> void:
	_lock_player(true)
	ControlManager.force_recall()
	if _room != null and is_instance_valid(_room) and _room != get_tree().current_scene:
		_room.queue_free()
	_room = null
	_player = null
	get_tree().change_scene_to_file(scene_path)


## 死亡重生：回最近检查点（可能跨房间重载）。由 player.die() 调用。
func respawn() -> void:
	if _transitioning:
		return
	# 无检查点上下文（独立测试场景未走 RoomBase 注册）：回退旧行为——spawn_point 组标记
	if GameState.checkpoint_room == "":
		var spawn := get_tree().get_first_node_in_group(&"spawn_point") as Node2D
		if spawn != null and _player_or_scene_player() != null:
			var p := _player_or_scene_player()
			_player = p
			p.global_position = spawn.global_position
			p.velocity = Vector2.ZERO
			p.reset_on_respawn()
			p.reset_physics_interpolation()
			_snap_camera_to_player()
		return
	_lock_player(true)
	ControlManager.force_recall()
	if GameState.checkpoint_room == current_room_id:
		# 本房间检查点：直接落位（不重建房间，体感更快）
		if _player != null:
			_player.global_position = GameState.checkpoint_position
			_player.velocity = Vector2.ZERO
			_player.reset_on_respawn()
			_player.reset_physics_interpolation()
			_snap_camera_to_player()
		_lock_player(false)
		return
	await goto_room(GameState.checkpoint_room, &"__checkpoint__")
	# goto_room 末尾已解锁并置位 _transitioning=false


func is_transitioning() -> bool:
	return _transitioning


## 当前房间实例（验证脚本用）
func get_active_room() -> Node2D:
	return _room


## 玩家引用：优先托管实例，否则查场景自带（独立测试场景直跑时）
func _player_or_scene_player() -> Player:
	if _player != null and is_instance_valid(_player):
		return _player
	return get_tree().get_first_node_in_group(&"player") as Player


func _ensure_player() -> void:
	# 持久玩家已在（跨房间摘下的游离状态）→ 直接挂进新房间
	if _player != null and is_instance_valid(_player):
		if _player.get_parent() == null:
			_player_parent().add_child(_player)
		return
	# 收养场景自带玩家（测试场景直跑）；都没有则实例化
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player == null:
		_player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
		_player_parent().add_child(_player)


func _player_parent() -> Node:
	var parent := _room.get_node_or_null("Characters")
	return parent if parent != null else _room


func _place_player(entrance: StringName) -> void:
	if _player == null or _room == null:
		return
	var pos := Vector2.ZERO
	var found := false
	if entrance == &"__checkpoint__":
		# 重生专用：直接使用检查点坐标
		pos = GameState.checkpoint_position
		found = true
	else:
		var marker := _room.get_node_or_null("Entrance_" + String(entrance)) as Node2D
		if marker == null:
			marker = _room.get_node_or_null("Entrance_default") as Node2D
		if marker == null:
			marker = _room.get_node_or_null("SpawnPoint") as Node2D
		if marker != null:
			pos = marker.global_position
			found = true
	if not found:
		push_warning("RoomManager: 房间 %s 缺少入口标记，玩家落在原点" % current_room_id)
	_player.global_position = pos
	_player.velocity = Vector2.ZERO
	_player.reset_on_respawn()
	# 房间级玩家参数（第 9 房间致幻延迟等，策划在房间根节点配）
	_player.input_delay = _room.get("player_input_delay")
	_player.reset_physics_interpolation()
	_snap_camera_to_player()


## 相机瞬移到玩家：pcam 的 follow_damping 会让镜头从上一位置摇过来（0.15s），
## 进房间/重生时应直接对准（用户反馈 2026-08-17）。teleport_position 为插件官方 API。
## 需等一帧：pcam 缓存的跟随目标是玩家瞬移前的旧位置，同帧调用会瞬移到旧坐标。
func _snap_camera_to_player() -> void:
	await get_tree().process_frame
	if _player == null or not is_instance_valid(_player):
		return
	var pcam := _player.get_node_or_null("PhantomCamera2D")
	if pcam != null and pcam.has_method("teleport_position"):
		pcam.teleport_position()


## 房间切换后把房间 Camera2D 的 limit 同步到玩家 pcam
## （pcam 直写坐标会绕过 Camera2D 钳制——progress.md 遗留项，M8 修复）
func _apply_room_camera_limits() -> void:
	if _room == null or _player == null:
		return
	var cam := _room.get_node_or_null("Camera2D") as Camera2D
	var pcam := _player.get_node_or_null("PhantomCamera2D")
	if cam == null or pcam == null:
		return
	pcam.set("limit_left", cam.limit_left)
	pcam.set("limit_top", cam.limit_top)
	pcam.set("limit_right", cam.limit_right)
	pcam.set("limit_bottom", cam.limit_bottom)


func _lock_player(locked: bool) -> void:
	if _player != null and is_instance_valid(_player):
		_player.control_active = not locked


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", alpha, 0.4)
	await tween.finished
