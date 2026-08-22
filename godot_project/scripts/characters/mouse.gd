extends CharacterBody2D
class_name Mouse
## 老鼠控制器（M5）：5.2 格/秒、2 格跳 + 1.5 格二段跳、16×8 判定（2026-08-20 正式素材 27×9/帧，判定取身体不含尾巴）、可过 1 格窄缝。
## 策划案 §二(二)3。input_delay 为第 9 房间"0.8s 操控延迟"机制，0 表示无延迟。

const TILE_SIZE := 16.0

@export var move_speed_tiles: float = 5.2
@export var jump_height_tiles: float = 2.0
@export var jump_time_to_apex: float = 0.3
@export var double_jump_height_tiles: float = 1.5
@export var fall_gravity_multiplier: float = 1.3
## 输入延迟（秒），第 9 房间机制
@export var input_delay: float = 0.0

var control_active: bool = false

var _gravity_up: float
var _gravity_down: float
var _jump_velocity: float
var _double_jump_velocity: float
var _air_time: float = 0.0
var _can_double_jump: bool = false
var _facing: int = 1
var _time: float = 0.0
# 输入采样环形缓冲：[时间, 横轴, 跳按下(0/1)]，供延迟回放
var _samples: Array[Vector3] = []

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _pcam: Node2D = $PhantomCamera2D


func _ready() -> void:
	var height := jump_height_tiles * TILE_SIZE
	_gravity_up = 2.0 * height / (jump_time_to_apex * jump_time_to_apex)
	_gravity_down = _gravity_up * fall_gravity_multiplier
	_jump_velocity = _gravity_up * jump_time_to_apex
	_double_jump_velocity = sqrt(2.0 * _gravity_up * double_jump_height_tiles * TILE_SIZE)


func set_pcam_priority(priority: int) -> void:
	_pcam.set("priority", priority)


func die() -> void:
	ControlManager.on_mouse_died()


## 取当前生效输入：无延迟直读，有延迟读 delay 秒前的采样
func _sample_input() -> Vector2:
	var now := _time
	var axis := 0.0
	var jump := 0.0
	if control_active:
		axis = Input.get_axis(&"move_left", &"move_right")
		jump = 1.0 if Input.is_action_just_pressed(&"jump") else 0.0
	_samples.append(Vector3(now, axis, jump))
	# 只保留延迟窗口 + 余量内的样本
	var keep_after := now - input_delay - 0.5
	while not _samples.is_empty() and _samples[0].x < keep_after:
		_samples.remove_at(0)
	if input_delay <= 0.0:
		return Vector2(axis, jump)
	var target := now - input_delay
	var chosen := Vector3(now, 0.0, 0.0)
	for s in _samples:
		if s.x <= target:
			chosen = s
		else:
			break
	return Vector2(chosen.y, chosen.z)


func _physics_process(delta: float) -> void:
	_time += delta
	var input := _sample_input()
	var axis := input.x

	var target_speed := axis * move_speed_tiles * TILE_SIZE
	velocity.x = move_toward(velocity.x, target_speed, 600.0 * delta)

	if is_on_floor():
		_air_time = 0.0
		_can_double_jump = true
	else:
		_air_time += delta
		var gravity := _gravity_up if velocity.y < 0.0 else _gravity_down
		velocity.y += gravity * delta

	if input.y > 0.5:
		if is_on_floor():
			velocity.y = -_jump_velocity
			_can_double_jump = true
		elif _can_double_jump:
			velocity.y = -_double_jump_velocity
			_can_double_jump = false

	if not is_zero_approx(axis):
		_facing = 1 if axis > 0.0 else -1
		_sprite.flip_h = _facing < 0

	move_and_slide()
	_update_animation()


func _update_animation() -> void:
	# 正式素材（2026-08-20 实装）：空中分上升/下降整图，与主角跳跃同规则
	var anim: StringName
	if not is_on_floor():
		anim = &"jump_rise" if velocity.y < 0.0 else &"jump_fall"
	elif absf(velocity.x) > 4.0:
		anim = &"run"
	else:
		anim = &"idle"
	_sprite.play(anim)
