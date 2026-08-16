@tool
extends Node2D
## 摇杆平台（M6）：玩家站上摇杆区按住 E，平台沿 move_offset 移动；松开/离开则复位。
## 路径在编辑器内可视化（虚线）。策划案 §三(五)。

## 平台移动偏移（px），从起点到终点
@export var move_offset: Vector2 = Vector2(96, 0):
	set(value):
		move_offset = value
		queue_redraw()
## 平台移动速度（px/秒）
@export var move_speed: float = 32.0

var _player_in_range: bool = false
var _progress: float = 0.0 # 0=起点 1=终点

@onready var _platform: AnimatableBody2D = $Platform
@onready var _lever_area: Area2D = $LeverArea
@onready var _platform_home: Vector2


func _ready() -> void:
	_platform_home = $Platform.position
	if Engine.is_editor_hint():
		return
	_lever_area.body_entered.connect(_on_body_entered)
	_lever_area.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# 按住 E 且站在摇杆旁才推进（策划案 §三(五)）
	var target := 1.0 if (_player_in_range and Input.is_action_pressed(&"interact")) else 0.0
	var length := move_offset.length()
	if length < 0.01:
		return
	var step := move_speed * delta / length
	_progress = move_toward(_progress, target, step)
	_platform.position = _platform_home + move_offset * _progress


func _draw() -> void:
	if Engine.is_editor_hint():
		# 路径可视化：平台中心起点的移动轨迹
		var from: Vector2 = $Platform.position + Vector2(24, 4)
		draw_dashed_line(from, from + move_offset, Color(0.4, 0.8, 1.0), 1.0, 4.0)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = false
