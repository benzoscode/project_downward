@tool
extends Node2D
## 发光机关节点（呼吸灯，2026-08-20 新增）：光强按正弦周期亮灭，颜色可自定义。
## 用于氛围点缀/路径提示，纯视觉发光体（无碰撞、无交互）。

@export_group("光效")
## 光的颜色（外发光颜色，可任意自定义）
@export var light_color: Color = Color(0.6, 0.85, 1.0):
	set(value):
		light_color = value
		_apply_color()
## 最小光强（暗）
@export_range(0.0, 10.0) var min_energy: float = 0.4
## 最大光强（亮）
@export_range(0.0, 10.0) var max_energy: float = 2.0
## 呼吸周期（秒）——一个完整亮→灭→亮的时长
@export_range(0.2, 20.0) var period: float = 3.0
## 是否随亮度同步缩放光斑（更"呼吸"）
@export var pulse_scale: bool = true

@onready var _light: PointLight2D = $PointLight2D


func _ready() -> void:
	_apply_color()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_apply_color()
		# 编辑器内推进预览（无 1s 基准，直接用当前时间）
		_update_energy(float(Time.get_ticks_msec() % 1000000) / 1000.0)
		return
	_update_energy(Time.get_ticks_msec() / 1000.0)


func _update_energy(t: float) -> void:
	# 0..1 呼吸相位，周期 period
	var phase := 0.5 + 0.5 * sin(TAU * t / period)
	_light.energy = lerpf(min_energy, max_energy, phase)
	if pulse_scale:
		_light.texture_scale = 0.6 + 0.4 * phase


func _apply_color() -> void:
	if is_node_ready():
		_light.color = light_color
