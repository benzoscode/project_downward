extends CharacterBody2D
class_name Player
## 玩家控制器：惯性移动 / 跳跃 / 土狼时间 / 跳跃缓冲。
## 数值依据策划案 §二(一)：移速 3 格/秒、跳跃 3 格、判定 12×20。

const TILE_SIZE := 16.0

@export_category("移动")
## 水平移动速度（格/秒），策划案 §二(一)2 固定 3 格/秒
@export var move_speed_tiles: float = 3.0
## 起步加速度（px/s²），惯性手感的来源
@export var acceleration: float = 400.0
## 松键减速度（px/s²），略大于加速度让停步更利落
@export var deceleration: float = 550.0

@export_category("跳跃")
## 跳跃高度（格），策划案 §二(一)2 固定 3 格
@export var jump_height_tiles: float = 3.0
## 起跳到顶点的时间（秒），与跳跃高度共同决定重力/初速度
@export var jump_time_to_apex: float = 0.35
## 下落重力倍率（>1 让下落比上升快，平台跳跃更干脆）
@export var fall_gravity_multiplier: float = 1.4
## 土狼时间（秒）：走出平台边缘后仍可起跳的宽限
@export var coyote_time: float = 0.1
## 跳跃缓冲（秒）：落地前提前按跳也生效的宽限
@export var jump_buffer: float = 0.1

var _gravity_up: float
var _gravity_down: float
var _jump_velocity: float
var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0
var _facing: int = 1

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_recalculate_jump()


## 由"跳跃高度 + 到顶点时间"反推重力与初速度，策划只调直觉参数
func _recalculate_jump() -> void:
	var height := jump_height_tiles * TILE_SIZE
	_gravity_up = 2.0 * height / (jump_time_to_apex * jump_time_to_apex)
	_gravity_down = _gravity_up * fall_gravity_multiplier
	_jump_velocity = _gravity_up * jump_time_to_apex


func _physics_process(delta: float) -> void:
	var axis := Input.get_axis(&"move_left", &"move_right")
	var target_speed := axis * move_speed_tiles * TILE_SIZE
	var rate := acceleration if absf(target_speed) > 0.01 else deceleration
	velocity.x = move_toward(velocity.x, target_speed, rate * delta)

	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
		var gravity := _gravity_up if velocity.y < 0.0 else _gravity_down
		velocity.y += gravity * delta

	if Input.is_action_just_pressed(&"jump"):
		_buffer_timer = jump_buffer
	else:
		_buffer_timer = maxf(0.0, _buffer_timer - delta)

	if _buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = -_jump_velocity
		_buffer_timer = 0.0
		_coyote_timer = 0.0

	if not is_zero_approx(axis):
		_facing = 1 if axis > 0.0 else -1
		_sprite.flip_h = _facing < 0

	move_and_slide()
	_update_animation()


func _update_animation() -> void:
	if not is_on_floor():
		_sprite.play(&"jump")
	elif absf(velocity.x) > 4.0:
		_sprite.play(&"run")
	else:
		_sprite.play(&"idle")
