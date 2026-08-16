extends Node2D
## 玩家照明灯：F 开关（需已拾取照明灯道具），60° 锥形、6 格射程、方向跟随鼠标。
## 策划案 §二(二)1。注册到 LightSystem 供光照判定查询。

## 射程（格），策划案 §二(二)1 为 6 格
@export var range_tiles: float = 6.0
## 锥形半角（度），全角 60°
@export var cone_half_angle_deg: float = 30.0
## 转向响应时间（秒）：越小转身时灯光跟随越快
@export var turn_duration: float = 0.12

var lamp_on: bool = false
var range_px: float
var half_angle: float
## 验证脚本用：锁定瞄准点后不再跟随朝向
var aim_locked: bool = false

@onready var _light: PointLight2D = $PointLight2D


func _ready() -> void:
	range_px = range_tiles * 16.0
	half_angle = deg_to_rad(cone_half_angle_deg)
	# 锥形贴图半径 64px（见 light_cone.png），缩放到射程
	_light.texture_scale = range_px / 64.0
	_light.visible = false
	LightSystem.register_lamp(self)


func _exit_tree() -> void:
	LightSystem.unregister_lamp(self)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"toggle_lamp") and GameState.has_lamp:
		lamp_on = not lamp_on
		_light.visible = lamp_on
	if not aim_locked:
		# 灯光跟随角色脸部朝向，转身时平滑转向
		var target_angle := 0.0 if (get_parent() as Player).get_facing() > 0 else PI
		global_rotation = lerp_angle(global_rotation, target_angle,
			1.0 - exp(-delta / turn_duration))


## 验证脚本：锁定瞄准到指定世界坐标
func lock_aim_to(point: Vector2) -> void:
	aim_locked = true
	global_rotation = (point - global_position).angle()


## 验证脚本：直接置灯状态（绕过道具门槛与输入）
func set_lamp_on(on: bool) -> void:
	lamp_on = on
	_light.visible = on
