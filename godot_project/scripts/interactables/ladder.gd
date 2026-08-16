@tool
extends Area2D
## 梯子：玩家在范围内按上/下进入攀爬，跳跃翻出（见 player.gd）。
## @tool：编辑器内拖动 height 即所见即所得。顶端应略高出平台边缘，便于爬到顶。

@export var height: int = 96:
	set(value):
		height = value
		_apply_size()

const WIDTH := 16

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: ColorRect = $ColorRect
@onready var _prompt: Label = $Prompt


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
	# 节点原点在梯子底部，向上延伸
	rect.size = Vector2(WIDTH, height)
	_collision.position = Vector2(WIDTH * 0.5, -height * 0.5)
	_visual.size = Vector2(WIDTH, height)
	_visual.position = Vector2(0, -height)
	_prompt.offset_top = -height - 12.0
	_prompt.offset_bottom = -height


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).enter_ladder()
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).exit_ladder()
		_prompt.visible = false
