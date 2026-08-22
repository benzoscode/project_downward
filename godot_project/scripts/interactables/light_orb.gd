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
@onready var _visual: Sprite2D = $Sprite2D

const ORB_TEX: Dictionary = {
	&"red": {"tex": preload("res://assets/props/orb_red.png"), "color": Color(0.9, 0.3, 0.3)},
	&"blue": {"tex": preload("res://assets/props/orb_blue.png"), "color": Color(0.3, 0.5, 0.95)},
	&"yellow": {"tex": preload("res://assets/props/orb_yellow.png"), "color": Color(0.95, 0.8, 0.3)},
}


func setup(initial_velocity: Vector2, tint: Color, life: float) -> void:
	velocity = initial_velocity
	life_time = life
	if is_node_ready():
		_apply_tint(tint)
	else:
		ready.connect(_apply_tint.bind(tint), CONNECT_ONE_SHOT)


## 按主色调映射到正式光球贴图（红/蓝/黄，2026-08-20 素材）；
## 发光颜色改为与正式图一致（用户拍板 2026-08-20），不再用传入 tint
func _apply_tint(tint: Color) -> void:
	var key: StringName = &"yellow"
	if tint.r > tint.b * 1.6 and tint.r > tint.g * 1.6:
		key = &"red"
	elif tint.b > tint.r * 1.6 and tint.b > tint.g * 1.6:
		key = &"blue"
	var info: Dictionary = ORB_TEX[key]
	_visual.texture = info["tex"]
	_visual.modulate = Color.WHITE
	_light.color = info["color"]


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
