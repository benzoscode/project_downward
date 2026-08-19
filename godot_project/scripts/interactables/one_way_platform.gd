@tool
extends StaticBody2D
## 单向平台：只从上方落脚，下方/侧面自由穿越；没有下落键——按 S 也不会掉下去
## （不同于常见单向平台，2026-08-18 用户需求）。引擎 one_way_collision 天然实现。
## @tool：编辑器拖 width_tiles 所见即所得。

## 平台宽度（格）
@export var width_tiles: float = 3.0:
	set(value):
		width_tiles = value
		_apply_size()

## 厚度（px），调试用，不建议改
const THICKNESS := 6.0
## 表面配色（与交替平台色系区分，用石青）
const TINT := Color(0.45, 0.65, 0.75)

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: ColorRect = $ColorRect


func _ready() -> void:
	_apply_size()


func _apply_size() -> void:
	if not is_node_ready():
		return
	var w := width_tiles * 16.0
	var rect := _collision.shape as RectangleShape2D
	rect.size = Vector2(w, THICKNESS)
	# one_way_collision 在 tscn 里已开：只挡从上方来的运动（向上为正 Y 反方向）
	_visual.size = Vector2(w, THICKNESS)
	_visual.position = Vector2(-w * 0.5, -THICKNESS * 0.5)
	_visual.color = TINT
