@tool
extends Node2D
## 摇杆平台（M6）：玩家站上摇杆区按住 E，平台沿 move_offset 移动；松开/离开则复位。
## 路径在编辑器内可视化（虚线）。策划案 §三(五)。

## 平台起始位置（相对摇杆的偏移，px）——摇杆与平台可分开摆放（2026-08-18 用户需求）
@export var platform_offset: Vector2 = Vector2(64, 0):
	set(value):
		platform_offset = value
		if is_node_ready():
			_platform.position = value
			_platform_home = value
		queue_redraw()
## 平台移动偏移（px），从起点到终点
@export var move_offset: Vector2 = Vector2(96, 0):
	set(value):
		move_offset = value
		queue_redraw()
## 平台移动速度（px/秒）
@export var move_speed: float = 32.0
## 松手后平台在终点的停留时间（秒），策划案难度表"平台停留时间"调节项
@export var dwell_time: float = 0.5

var _player_in_range: bool = false
var _progress: float = 0.0 # 0=起点 1=终点
var _dwell_left: float = 0.0 # 松手后剩余停留时间

@onready var _platform: AnimatableBody2D = $Platform
@onready var _lever_area: Area2D = $LeverArea
@onready var _platform_home: Vector2


func _ready() -> void:
	_platform.position = platform_offset
	_platform_home = platform_offset
	if Engine.is_editor_hint():
		return
	_lever_area.body_entered.connect(_on_body_entered)
	_lever_area.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var length := move_offset.length()
	if length < 0.01:
		return
	var holding := _player_in_range and Input.is_action_pressed(&"interact")
	if holding:
		_dwell_left = dwell_time
		_progress = move_toward(_progress, 1.0, move_speed * delta / length)
	else:
		# 松手后先在终点停留 dwell_time，再复位（玩家追平台的窗口）
		_dwell_left = maxf(0.0, _dwell_left - delta)
		if _dwell_left <= 0.0:
			_progress = move_toward(_progress, 0.0, move_speed * delta / length)
	_platform.position = _platform_home + move_offset * _progress


func _draw() -> void:
	if Engine.is_editor_hint():
		# 路径可视化：平台起点/终点幽灵框 + 移动轨迹虚线
		var from: Vector2 = platform_offset + Vector2(24, 4)
		var to := from + move_offset
		draw_dashed_line(from, to, Color(0.4, 0.8, 1.0), 1.0, 4.0)
		draw_rect(Rect2(to - Vector2(24, 4), Vector2(48, 8)), Color(0.4, 0.8, 1.0, 0.35), false, 1.0)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = false
