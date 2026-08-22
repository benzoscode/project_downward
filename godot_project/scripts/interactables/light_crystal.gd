extends Node2D
## 光敏水晶：被玩家锥形灯持续照射 charge_time 秒激活，广播 target_id（MechanismBus）。
## 策划案 §二(二)1：照射 2 秒激活。激活后保持（机关状态保留，§一）。

## 激活后广播的机关 ID
@export var target_id: StringName
## 需要持续照射的秒数，策划案定 2 秒
@export var charge_time: float = 2.0

var _charge: float = 0.0
var _activated: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
# 正式素材仅一张（2026-08-20）：激活态靠辉光 + 满亮度区分，不换图
@onready var _tex_off: Texture2D = preload("res://assets/props/crystal_light.png")
@onready var _tex_on: Texture2D = _tex_off
@onready var _glow: PointLight2D = $Glow


func _ready() -> void:
	# 死亡重生不重置：总线已触发则直接亮
	if MechanismBus.is_triggered(target_id):
		_activate(true)


func _physics_process(delta: float) -> void:
	if _activated:
		return
	if LightSystem.is_point_lit(global_position):
		_charge = minf(_charge + delta, charge_time)
	else:
		_charge = 0.0
	# 进度反馈：随充能提高亮度
	var t := _charge / charge_time
	_sprite.modulate = Color(0.4 + 0.6 * t, 0.4 + 0.6 * t, 0.4 + 0.6 * t)
	if _charge >= charge_time:
		_activate(false)


func _activate(instant: bool) -> void:
	_activated = true
	_sprite.texture = _tex_on
	_sprite.modulate = Color.WHITE
	_glow.visible = true
	if not instant:
		MechanismBus.trigger(target_id)
		Sfx.play(&"crystal_activate")
	else:
		# 重生恢复：只补视觉，总线状态已存在，不重复发信号
		pass


func is_activated() -> bool:
	return _activated
