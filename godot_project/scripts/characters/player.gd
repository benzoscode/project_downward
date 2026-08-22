extends CharacterBody2D
class_name Player
## 玩家控制器：惯性移动 / 跳跃 / 土狼时间 / 跳跃缓冲 / 攀爬 / 水域 / 交互 / 死亡重生。
## 数值依据策划案 §二(一)：移速 3 格/秒、跳跃 3 格、判定 12×20。

const TILE_SIZE := 16.0

@export_category("移动")
## 行走速度（格/秒）。策划案原值 3，2026-08-17 手感调校为 4（decisions.md）
@export var move_speed_tiles: float = 4.0
## 奔跑速度（格/秒）：按住 Shift 奔跑，松开回行走（2026-08-18 用户确认为按住式）
@export var run_speed_tiles: float = 6.0
## 起步加速度（px/s²），惯性手感的来源
@export var acceleration: float = 400.0
## 松键减速度（px/s²），略大于加速度让停步更利落
@export var deceleration: float = 550.0

@export_category("跳跃")
## 跳跃高度（格），策划案 §二(一)2 固定 3 格
@export var jump_height_tiles: float = 3.0
## 起跳到顶点的时间（秒），与跳跃高度共同决定重力/初速度
@export var jump_time_to_apex: float = 0.35
## 下落重力倍率（>1 让下落比上升快）。2026-08-20 用户反馈坠落太快：1.4→0.7（减半）；
## 上升段不受影响，跳跃到顶高度保持 3 格不变
@export var fall_gravity_multiplier: float = 0.7
## 土狼时间（秒）：走出平台边缘后仍可起跳的宽限
@export var coyote_time: float = 0.1
## 跳跃缓冲（秒）：落地前提前按跳也生效的宽限
@export var jump_buffer: float = 0.1

@export_category("二段跳（羽翎靴）")
## 二段跳高度（格），策划案 §二(二)2：合计 3+2=5 格
@export var double_jump_height_tiles: float = 2.0
## 起跳后多少秒内不可触发二段跳（防误触，策划案 §二(二)2）
@export var double_jump_lockout: float = 0.2

@export_category("攀爬")
## 梯子攀爬速度（格/秒），刻意慢于平地行走；2026-08-17 手感调校 2→3
@export var climb_speed_tiles: float = 3.0

@export_category("水域")
## 水中水平移速倍率，策划案 §二(三)：浸入减速
@export_range(0.1, 1.0) var water_speed_multiplier: float = 0.5
## 水中重力倍率，略小于 1 制造浮力感
@export_range(0.1, 1.0) var water_gravity_multiplier: float = 0.6
## 入水瞬间垂直速度保留比例（0.3 = 砍掉七成下坠冲量，2026-08-18 用户反馈落水减速不明显）
@export_range(0.0, 1.0) var water_entry_damp: float = 0.3
## 水中坠落终速上限（格/秒），缓沉手感
@export var water_max_fall_tiles: float = 2.5

@export_category("致幻（第 9 房间）")
## 输入延迟（秒）：第 9 房间致幻机制。M6 决策：渲染延迟方案风险高，降级为输入延迟
@export var input_delay: float = 0.0

var _gravity_up: float
var _gravity_down: float
var _jump_velocity: float
var _double_jump_velocity: float
var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0
var _facing: int = 1
var _air_time: float = 0.0
var _press_air_time: float = -1.0 # 本次跳跃缓冲按下时的空中时长（防误触窗口按按键时刻判定）
var _can_double_jump: bool = false

var _interactable: Node = null # 当前可交互对象，由可交互积木注册/注销
var _water_count: int = 0
var _ladder_count: int = 0
var _climbing: bool = false
var _ladder_center_x: float = 0.0 # 攀爬锁定中线（用户反馈 2026-08-17：不许在梯子两侧爬）
var _running: bool = false # Shift 切换的奔跑状态
## 操控权标记（M5）：ControlManager 切换老鼠时置 false，玩家静止但保留重力
var control_active: bool = true
var _time: float = 0.0
# 输入采样缓冲：[t, axis, axis_y, jump, interact]，供致幻延迟回放
var _input_samples: Array = []

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _ground_probe: RayCast2D = $GroundProbe
@onready var _lamp: Node2D = $Lamp


## 是否正在攀爬（供验证脚本与调试断言）
func is_climbing() -> bool:
	return _climbing


func _ready() -> void:
	_recalculate_jump()
	ControlManager.register_player(self)


## 由"跳跃高度 + 到顶点时间"反推重力与初速度，策划只调直觉参数
func _recalculate_jump() -> void:
	var height := jump_height_tiles * TILE_SIZE
	_gravity_up = 2.0 * height / (jump_time_to_apex * jump_time_to_apex)
	_gravity_down = _gravity_up * fall_gravity_multiplier
	_jump_velocity = _gravity_up * jump_time_to_apex
	# 二段跳：同一上升重力下达到 2 格所需的初速度
	_double_jump_velocity = sqrt(2.0 * _gravity_up * double_jump_height_tiles * TILE_SIZE)


## 死亡重生：回最近检查点（M8 起由 RoomManager 处理，可跨房间；
## 机关状态由 MechanismBus 保留，策划案 §一）
func die() -> void:
	RoomManager.respawn()


## 重生时清理瞬态（攀爬等），由 RoomManager 调用
func reset_on_respawn() -> void:
	_climbing = false


# ---- 积木注册接口（积木通过 is_in_group("player") 拿到本节点后调用）----

func set_interactable(node: Node) -> void:
	_interactable = node


func clear_interactable(node: Node) -> void:
	if _interactable == node:
		_interactable = null


func enter_water() -> void:
	_water_count += 1
	_sprite.modulate.a = 0.65
	# 入水瞬间砍掉大部分下坠冲量（落水缓冲）
	velocity.y *= water_entry_damp


func exit_water() -> void:
	_water_count = maxi(0, _water_count - 1)
	if _water_count == 0:
		_sprite.modulate.a = 1.0


func enter_ladder(center_x: float) -> void:
	_ladder_count += 1
	_ladder_center_x = center_x


func exit_ladder() -> void:
	_ladder_count = maxi(0, _ladder_count - 1)
	if _ladder_count == 0:
		_climbing = false


func _physics_process(delta: float) -> void:
	_time += delta
	# 采样当前输入（无操控权时记零），致幻延迟时回放 delay 秒前的采样
	var raw := [0.0, 0.0, 0.0, 0.0]
	if control_active:
		raw[0] = Input.get_axis(&"move_left", &"move_right")
		raw[1] = Input.get_axis(&"move_up", &"move_down")
		raw[2] = 1.0 if Input.is_action_just_pressed(&"jump") else 0.0
		raw[3] = 1.0 if Input.is_action_just_pressed(&"interact") else 0.0
	_input_samples.append([_time, raw[0], raw[1], raw[2], raw[3]])
	var keep_after := _time - input_delay - 0.5
	while not _input_samples.is_empty() and _input_samples[0][0] < keep_after:
		_input_samples.remove_at(0)
	var eff: Array = [_time, raw[0], raw[1], raw[2], raw[3]]
	if input_delay > 0.0:
		var target := _time - input_delay
		eff = [_time, 0.0, 0.0, 0.0, 0.0]
		for s in _input_samples:
			if s[0] <= target:
				eff = s
			else:
				break
	var axis: float = eff[1]
	var axis_y: float = eff[2]
	var jump_just: bool = eff[3] > 0.5
	var interact_just: bool = eff[4] > 0.5
	var in_water := _water_count > 0

	# 奔跑按住即跑、松开即走（不进延迟缓冲，保证手感响应）
	_running = control_active and Input.is_action_pressed(&"hold_run")

	if interact_just and _interactable != null:
		_interactable.interact()

	# 攀爬：在梯子范围内按上下进入；跳跃或离开梯子退出
	if not _climbing and _ladder_count > 0 and absf(axis_y) > 0.01:
		_climbing = true
		velocity = Vector2.ZERO
	if _climbing:
		if _ladder_count == 0:
			_climbing = false
		elif jump_just:
			# 梯上跳出：完整跳跃 + 水平速度按当前方向输入，实现"跳+左右"跃出
			_climbing = false
			velocity.y = -_jump_velocity
			velocity.x = axis * move_speed_tiles * TILE_SIZE
		else:
			velocity.y = axis_y * climb_speed_tiles * TILE_SIZE
			velocity.x = 0.0
			# 攀爬全程锁在梯子中线
			global_position.x = _ladder_center_x
			# 接近地面（探测 20px 内）按左右直接走下梯子；梯顶同理可侧向走上平台。
			# 纯按左右在半空不会脱手。触地时若非上升中（避免起步帧误判）也退出攀爬。
			if (is_on_floor() and axis_y >= 0.0) or (_ground_probe.is_colliding() and absf(axis) > 0.01):
				_climbing = false

	var speed_multiplier := water_speed_multiplier if in_water else 1.0
	var speed_tiles := run_speed_tiles if _running else move_speed_tiles
	var target_speed := axis * speed_tiles * TILE_SIZE * speed_multiplier
	var rate := acceleration if absf(target_speed) > 0.01 else deceleration
	# 攀爬中锁水平移动：只能跳+方向跃出，或在近地/平台边按左右走下
	if not _climbing:
		velocity.x = move_toward(velocity.x, target_speed, rate * delta)

	if not _climbing:
		if is_on_floor():
			_coyote_timer = coyote_time
			_air_time = 0.0
			_can_double_jump = true
		else:
			_coyote_timer = maxf(0.0, _coyote_timer - delta)
			_air_time += delta
			var gravity := _gravity_up if velocity.y < 0.0 else _gravity_down
			if in_water:
				gravity *= water_gravity_multiplier
			velocity.y += gravity * delta
			# 水中坠落限速（缓沉）
			if in_water:
				velocity.y = minf(velocity.y, water_max_fall_tiles * TILE_SIZE)

		if jump_just:
			_buffer_timer = jump_buffer
			_press_air_time = _air_time
		else:
			_buffer_timer = maxf(0.0, _buffer_timer - delta)

		if _buffer_timer > 0.0:
			if _coyote_timer > 0.0:
				velocity.y = -_jump_velocity
				_buffer_timer = 0.0
				_coyote_timer = 0.0
			elif _can_double_jump and _press_air_time >= double_jump_lockout and GameState.has_boots:
				# 二段跳：重置空中水平速度为当前输入方向（策划案 §二(二)2）
				velocity.y = -_double_jump_velocity
				velocity.x = axis * move_speed_tiles * TILE_SIZE
				_can_double_jump = false
				_buffer_timer = 0.0
				# 羽翎靴外观：脚下拖出气流粒子（策划案 §二(二)2）
				var puff := (preload("res://scenes/effects/airflow_puff.tscn") as PackedScene).instantiate() as Node2D
				puff.global_position = global_position + Vector2(0, 10)
				get_parent().add_child(puff)

	if not is_zero_approx(axis):
		_facing = 1 if axis > 0.0 else -1
		_sprite.flip_h = _facing < 0
		# 灯笼在素材手部位置（帧内 14,16 → 本地 (6,2)），朝向翻转时灯位同步镜像
		_lamp.position.x = 6.0 * _facing

	move_and_slide()
	_update_animation()


func _update_animation() -> void:
	# 正式素材（2026-08-17 实装）：每个状态分无灯/有灯两版
	# 跳跃上升/下落分图（2026-08-20 实装）；攀爬独立序列帧（无灯光差分）
	if _climbing:
		# 攀爬素材为上爬序列（2026-08-20）：下爬倒放，静止时停在当前帧
		if velocity.y > 0.01:
			_sprite.play_backwards(&"climb")
		elif velocity.y < -0.01:
			_sprite.play(&"climb")
		else:
			_sprite.pause()
		return
	var base: StringName
	if not is_on_floor():
		base = &"jump_rise" if velocity.y < 0.0 else &"jump_fall"
	elif absf(velocity.x) > 4.0:
		base = &"run"
	else:
		base = &"idle"
	var lamp_on: bool = _lamp.get("lamp_on")
	_sprite.play(base + (&"_lamp" if lamp_on else &""))
