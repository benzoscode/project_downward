@tool
extends Node2D
## 摇杆吊桥（2026-08-20 需求）：摇杆与吊桥可分开摆放，位置均可自定义。
## 玩家在摇杆区按住 E → 吊桥升起；停止互动 → 吊桥以 lower_speed 缓慢下降回起始位置。
## 升起终点在编辑器内可视化（幽灵框 + 虚线）。

## 吊桥起始位置（相对摇杆的偏移，px）
@export var bridge_offset: Vector2 = Vector2(96, 0):
	set(value):
		bridge_offset = value
		if is_node_ready():
			_bridge.position = value
			_bridge_home = value
		queue_redraw()
## 升起位移（px），默认竖直向上 3 格
@export var raise_offset: Vector2 = Vector2(0, -48):
	set(value):
		raise_offset = value
		queue_redraw()
## 升起速度（px/秒）
@export var raise_speed: float = 48.0
## 下降速度（px/秒），刻意慢于升起制造紧张感
@export var lower_speed: float = 20.0
## 吊绳顶端锚点（相对摇杆根节点，本地 y；默认桥上 4 格）
@export var rope_anchor_y: float = -64.0

## 吊桥左侧宽度的一半（绳挂在桥角），默认桥宽 32/2
const BRIDGE_HALF_W := 16.0

var _player_in_range: bool = false
var _progress: float = 0.0 # 0=起始（放下） 1=升起终点
var _bridge_home: Vector2

@onready var _bridge: AnimatableBody2D = $Bridge
@onready var _lever_area: Area2D = $LeverArea
@onready var _rope_left: TextureRect = $RopeLeft
@onready var _rope_right: TextureRect = $RopeRight


func _ready() -> void:
	_bridge.position = bridge_offset
	_bridge_home = bridge_offset
	if Engine.is_editor_hint():
		return
	_lever_area.body_entered.connect(_on_body_entered)
	_lever_area.body_exited.connect(_on_body_exited)
	_update_ropes()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var length := raise_offset.length()
	if length < 0.01:
		return
	if _player_in_range and Input.is_action_pressed(&"interact"):
		_progress = move_toward(_progress, 1.0, raise_speed * delta / length)
	else:
		# 停止互动立即缓慢下降，直至回到起始位置（无停留窗口，与摇杆平台区分）
		_progress = move_toward(_progress, 0.0, lower_speed * delta / length)
	_bridge.position = _bridge_home + raise_offset * _progress
	_update_ropes()


## 绳端顶部固定于 rope_anchor_y（本地），长度随吊桥升降伸缩（平铺绳段）
func _update_ropes() -> void:
	var bridge_top := _bridge.global_position.y - 4.0
	var anchor_y := to_global(Vector2(0, rope_anchor_y)).y
	var len := maxf(0.0, bridge_top - anchor_y) + 4.0
	var bridge_cx := _bridge.global_position.x
	for side: float in [-1.0, 1.0]:
		var rope: TextureRect = _rope_left if side < 0.0 else _rope_right
		var x: float = bridge_cx + side * BRIDGE_HALF_W
		# 世界坐标 → 本节点局部
		var local := to_local(Vector2(x, anchor_y))
		rope.position = local
		rope.size = Vector2(16.0, len)


func _draw() -> void:
	if Engine.is_editor_hint():
		# 路径可视化：吊桥起点/终点幽灵框 + 升降轨迹虚线
		var from: Vector2 = bridge_offset + Vector2(16, 4)
		var to := from + raise_offset
		draw_dashed_line(from, to, Color(1.0, 0.75, 0.3), 1.0, 4.0)
		draw_rect(Rect2(to - Vector2(16, 4), Vector2(32, 8)), Color(1.0, 0.75, 0.3, 0.35), false, 1.0)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = false
