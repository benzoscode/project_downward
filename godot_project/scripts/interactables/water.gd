@tool
extends Area2D
## 水体：玩家浸入减速 + 半透明视觉（策划案 §二(三)）。
## @tool：编辑器内拖动 size 即所见即所得；运行时才有进出逻辑。

@export var size: Vector2i = Vector2i(96, 48):
	set(value):
		size = value
		_apply_size()

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: ColorRect = $ColorRect


func _ready() -> void:
	_apply_size()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _apply_size() -> void:
	if not is_node_ready():
		return
	var rect := _collision.shape as RectangleShape2D
	if rect == null:
		return
	rect.size = Vector2(size)
	_collision.position = Vector2(size) * 0.5
	_visual.size = Vector2(size)
	_visual.position = Vector2.ZERO


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).enter_water()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).exit_water()
