@tool
extends CharacterBody2D
class_name Boss
## 地底猎食者（M7）：五状态状态机（巡逻/警戒/追击/搜索/分心），转换条件按策划案 §二(四)2 表格。
## 感知规则（§二(四)3）：光即威胁——玩家开灯或暴露于环境光即被感知；老鼠 ≤6 格优先于玩家。
## 追击为"直线 + 跳跃绕障"简化方案（milestones M7：不做完整寻路）。

enum State { PATROL, ALERT, CHASE, SEARCH, DISTRACTED }

const TILE_SIZE := 16.0
const STATE_NAMES: Array[String] = ["Patrol", "Alert", "Chase", "Search", "Distracted"]
# 正式动画映射（2026-08-20）：巡逻/警戒/搜索=idle，追击/分心=move；attack 预留（接触扑杀无攻击动作）
const STATE_ANIMS: Array[StringName] = [&"idle", &"idle", &"move", &"idle", &"move"]

@export_category("感知（策划案 §二(四)2/4）")
## 追击距离（格）：开灯或暴露于环境光的玩家在此距离内立即被追击
@export var chase_range_tiles: float = 8.0
## 警戒距离上限（格）：光源在此距离内进入警戒，更远则无法感知（策划案未封顶，取 12 格）
@export var alert_range_tiles: float = 12.0
## 分心距离（格）：老鼠进入此距离时 Boss 放弃当前目标优先追击老鼠
@export var distract_range_tiles: float = 6.0

@export_category("移动")
## 巡逻速度（格/秒），缓慢徘徊
@export var patrol_speed_tiles: float = 1.5
## 警戒接近速度（格/秒）
@export var alert_speed_tiles: float = 2.5
## 追击速度（格/秒），必须快于玩家步行 3 格/秒（§二(四)1）
@export var chase_speed_tiles: float = 4.5
## 绕障跳跃高度（格），追击/分心时撞墙或目标在高处时起跳
@export var jump_height_tiles: float = 2.0

@export_category("巡逻")
## 巡逻路径（可选）：指定后沿路径点往返；不指定则在出生点两侧 patrol_half_extent 内往返
@export var patrol_route: Path2D
## 无路径时的巡逻半幅（格）
@export var patrol_half_extent_tiles: float = 6.0

@export_category("搜索")
## 搜索持续秒数，超时回巡逻（策划案定 10 秒）
@export var search_duration: float = 10.0
## 搜索徘徊半幅（格）：在最后已知位置附近来回探查
@export var search_wander_tiles: float = 2.0

## 状态切换信号，供验证脚本与调试监听
signal state_changed(old_state: State, new_state: State)

var _state: State = State.PATROL
var _target_pos: Vector2 # 追击/搜索锚点：玩家或老鼠的最后已知位置
var _search_timer: float = 0.0
var _home: Vector2
var _waypoints: PackedVector2Array = []
var _waypoint_index: int = 0
var _waypoint_dir: int = 1
var _facing: int = 1

var _gravity_up: float
var _gravity_down: float
var _jump_velocity: float
# LightSystem 运行期缓存：经根节点查询而非直引用 Autoload 名，--script 模式（无 Autoload）下编译期解析会失败
var _light_system: Node = null

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _kill_zone: Area2D = $KillZone


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_home = global_position
	var jump_height := jump_height_tiles * TILE_SIZE
	_gravity_up = 2.0 * jump_height / (0.3 * 0.3)
	_gravity_down = _gravity_up * 1.3
	_jump_velocity = _gravity_up * 0.3
	if patrol_route != null and patrol_route.curve != null and patrol_route.curve.point_count >= 2:
		for i in patrol_route.curve.point_count:
			_waypoints.append(patrol_route.to_global(patrol_route.curve.get_point_position(i)))
	_kill_zone.body_entered.connect(_on_kill_zone_body_entered)
	_apply_state_visual()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


## 当前状态（验证脚本用）
func get_state() -> State:
	return _state


func get_state_name() -> String:
	return STATE_NAMES[_state]


## 验证脚本用：重置到指定位置并强制回巡逻态（无巡逻路径时该位置即新巡逻中心）
func reset_to_patrol(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_home = pos
	_target_pos = pos
	_search_timer = 0.0
	_waypoint_index = 0
	_waypoint_dir = 1
	var old := _state
	_state = State.PATROL
	_apply_state_visual()
	if old != State.PATROL:
		state_changed.emit(old, State.PATROL)
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var mouse := _visible_mouse()
	var threat := _player_threat()

	# 老鼠优先：警戒/追击/搜索中老鼠进入感知范围即转分心（§二(四)3 优先级规则；
	# 搜索系追击的延续，一并纳入，避免老鼠从 Boss 眼前走过被无视）
	if mouse != null and _state in [State.ALERT, State.CHASE, State.SEARCH]:
		_target_pos = mouse.global_position
		_change_state(State.DISTRACTED)

	match _state:
		State.PATROL:
			if threat >= 2:
				_change_state(State.CHASE)
			elif threat == 1:
				_change_state(State.ALERT)
			else:
				_patrol_move()
		State.ALERT:
			if threat >= 2:
				_change_state(State.CHASE)
			elif threat == 0:
				# 光源消失 → 回巡逻（§二(四)2 状态图）
				_change_state(State.PATROL)
			else:
				_approach(_target_pos, alert_speed_tiles)
		State.CHASE:
			if threat == 0:
				# 目标脱离感知（关灯/超程/遮挡）→ 在最后已知位置搜索
				_enter_search()
			else:
				_chase_move(_target_pos)
		State.DISTRACTED:
			if mouse == null:
				# 捕获（KillZone 触发 mouse.die()）或老鼠消失 → 搜索其最后位置
				_enter_search()
			elif not _mouse_in_range(mouse):
				# 老鼠脱离感知范围 → 搜索（§二(四)3）
				_target_pos = mouse.global_position
				_enter_search()
			else:
				_target_pos = mouse.global_position
				_chase_move(_target_pos)
		State.SEARCH:
			if threat >= 1:
				# 搜索中重新感知到光源 → 立即恢复追击
				_change_state(State.CHASE)
			else:
				_search_timer -= delta
				if _search_timer <= 0.0:
					_change_state(State.PATROL)
				else:
					_search_move()

	# 重力（各状态共用，Boss 始终贴地）
	if not is_on_floor():
		velocity.y += (_gravity_up if velocity.y < 0.0 else _gravity_down) * delta
	move_and_slide()


# ---- 感知 ----

## 玩家威胁等级：0 无 / 1 警戒级（>chase_range）/ 2 追击级（≤chase_range）
func _player_threat() -> int:
	# 走组查询而非 ControlManager：--script 模式（无 Autoload）下编译期解析会失败
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return 0
	var exposed := false
	var ls := _ls()
	if ls != null:
		var lamp_threat: bool = ls.is_lamp_on()
		var ambient_threat: bool = ls.is_point_lit_ambient(player.global_position)
		exposed = lamp_threat or ambient_threat
	if not exposed:
		return 0
	# 感光细胞判定：玩家与 Boss 之间有地形遮挡则光到不了 Boss（与遮光层同几何）
	if not ls.has_clear_line(global_position, player.global_position):
		return 0
	var dist := global_position.distance_to(player.global_position)
	if dist <= chase_range_tiles * TILE_SIZE:
		_target_pos = player.global_position
		return 2
	if dist <= alert_range_tiles * TILE_SIZE:
		_target_pos = player.global_position
		return 1
	return 0


## 感知范围内的老鼠（分心判定，≤distract_range 且视线无遮挡），无则 null
func _visible_mouse() -> Mouse:
	var mouse := get_tree().get_first_node_in_group(&"mouse") as Mouse
	if mouse == null or not is_instance_valid(mouse):
		return null
	if not _mouse_in_range(mouse):
		return null
	var ls := _ls()
	if ls == null or not ls.has_clear_line(global_position, mouse.global_position):
		return null
	return mouse


func _ls() -> Node:
	if _light_system == null:
		_light_system = get_tree().root.get_node_or_null(^"LightSystem")
	return _light_system


func _mouse_in_range(mouse: Mouse) -> bool:
	return global_position.distance_to(mouse.global_position) <= distract_range_tiles * TILE_SIZE


# ---- 各状态行为 ----

func _patrol_move() -> void:
	var target_x: float
	if _waypoints.size() >= 2:
		var wp := _waypoints[_waypoint_index]
		target_x = wp.x
		if absf(global_position.x - wp.x) < 6.0:
			_waypoint_index += _waypoint_dir
			if _waypoint_index >= _waypoints.size() or _waypoint_index < 0:
				_waypoint_dir = -_waypoint_dir
				_waypoint_index = clampi(_waypoint_index, 0, _waypoints.size() - 1)
	else:
		var left := _home.x - patrol_half_extent_tiles * TILE_SIZE
		var right := _home.x + patrol_half_extent_tiles * TILE_SIZE
		target_x = right if _facing > 0 else left
		if global_position.x >= right:
			target_x = left
		elif global_position.x <= left:
			target_x = right
	_walk_toward(target_x, patrol_speed_tiles)


func _approach(target: Vector2, speed_tiles: float) -> void:
	_walk_toward(target.x, speed_tiles)


func _chase_move(target: Vector2) -> void:
	_walk_toward(target.x, chase_speed_tiles)
	# 简化绕障：撞墙或目标明显高于自身时起跳（milestones M7 允许不做完整寻路）
	if is_on_floor() and (is_on_wall() or target.y < global_position.y - 24.0):
		velocity.y = -_jump_velocity


func _search_move() -> void:
	var left := _target_pos.x - search_wander_tiles * TILE_SIZE
	var right := _target_pos.x + search_wander_tiles * TILE_SIZE
	var target_x := right if _facing > 0 else left
	if global_position.x >= right:
		target_x = left
	elif global_position.x <= left:
		target_x = right
	_walk_toward(target_x, patrol_speed_tiles)


func _walk_toward(target_x: float, speed_tiles: float) -> void:
	var dx := target_x - global_position.x
	if absf(dx) < 2.0:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * get_physics_process_delta_time())
		return
	var dir := signf(dx)
	velocity.x = move_toward(velocity.x, dir * speed_tiles * TILE_SIZE, 800.0 * get_physics_process_delta_time())
	_facing = 1 if dir > 0.0 else -1
	_sprite.flip_h = _facing < 0


# ---- 状态切换 ----

func _enter_search() -> void:
	_search_timer = search_duration
	_change_state(State.SEARCH)


func _change_state(new_state: State) -> void:
	if new_state == _state:
		return
	var old := _state
	_state = new_state
	_apply_state_visual()
	# 进入追击/分心时低吼，提示玩家被盯上
	if new_state in [State.CHASE, State.DISTRACTED]:
		Sfx.play(&"boss_roar")
	state_changed.emit(old, new_state)


func _apply_state_visual() -> void:
	if _sprite != null:
		_sprite.play(STATE_ANIMS[_state])


# ---- 扑杀 ----

func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"mouse"):
		if _state == State.DISTRACTED:
			# 捕获老鼠：老鼠消失进 5s 冷却（ControlManager），Boss 转搜索（§二(四)3）
			_target_pos = body.global_position
			(body as Mouse).die()
	elif body.is_in_group(&"player"):
		if _state == State.CHASE:
			# 接触扑杀：玩家回出生点（§二(四)3）
			(body as Player).die()


# ---- 编辑器可视化 ----

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	# 感知圈：红=追击 8 格、黄=警戒 12 格、紫=分心 6 格
	draw_arc(Vector2.ZERO, chase_range_tiles * TILE_SIZE, 0.0, TAU, 48, Color(1, 0.3, 0.3, 0.6), 1.5)
	draw_arc(Vector2.ZERO, alert_range_tiles * TILE_SIZE, 0.0, TAU, 48, Color(1, 0.85, 0.3, 0.4), 1.0)
	draw_arc(Vector2.ZERO, distract_range_tiles * TILE_SIZE, 0.0, TAU, 48, Color(0.85, 0.5, 1, 0.6), 1.5)
	# 巡逻范围：有路径画路径折线，无路径画出生点半幅横线
	if patrol_route != null and patrol_route.curve != null and patrol_route.curve.point_count >= 2:
		var pts := PackedVector2Array()
		for i in patrol_route.curve.point_count:
			pts.append(to_local(patrol_route.to_global(patrol_route.curve.get_point_position(i))))
		draw_polyline(pts, Color(0.4, 0.9, 1, 0.7), 1.5)
	else:
		var half := patrol_half_extent_tiles * TILE_SIZE
		# 出生点即巡逻中心，本地坐标原点即节点位置
		draw_line(Vector2(-half, 0), Vector2(half, 0), Color(0.4, 0.9, 1, 0.7), 1.5)
