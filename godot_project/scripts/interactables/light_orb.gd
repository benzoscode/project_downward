extends CharacterBody2D
class_name LightOrb
## 光球（orb_launcher 发射，2026-08-18 用户需求）：初速度沿发射方向，随后受衰减重力缓慢下坠，
## 终身发光，life_time 秒后消散。撞地形会滑行/停下（不弹跳）。

## 重力衰减系数：下坠明显慢于自由落体（"减慢坠落"）
const GRAVITY_FACTOR := 0.18
## 下坠终速上限（px/s），光球缓降感的来源
const MAX_FALL_SPEED := 42.0
const GRAVITY := 800.0

var life_time: float = 10.0
var _age: float = 0.0

@onready var _light: PointLight2D = $PointLight2D
@onready var _visual: ColorRect = $ColorRect


func setup(initial_velocity: Vector2, tint: Color, life: float) -> void:
	velocity = initial_velocity
	life_time = life
	if is_node_ready():
		_apply_tint(tint)
	else:
		ready.connect(_apply_tint.bind(tint), CONNECT_ONE_SHOT)


func _apply_tint(tint: Color) -> void:
	_light.color = tint
	_visual.color = tint


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= life_time:
		queue_free()
		return
	velocity.y = minf(velocity.y + GRAVITY * GRAVITY_FACTOR * delta, MAX_FALL_SPEED)
	move_and_slide()
	# 末端 1 秒闪烁提示即将消散
	if life_time - _age < 1.0:
		_visual.modulate.a = 0.4 + 0.6 * absf(sin(_age * 12.0))
