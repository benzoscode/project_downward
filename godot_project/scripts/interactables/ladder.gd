@tool
extends Area2D
## 梯子：玩家在范围内按上/下进入攀爬，跳跃翻出（见 player.gd）。
## @tool：编辑器内拖动 height 即所见即所得。顶端应略高出平台边缘，便于爬到顶。
## 提示双位：玩家靠近哪一端就显示哪一端的 W/S 提示。

@export var height: int = 96:
	set(value):
		height = value
		_apply_size()

const WIDTH := 16

var _player: Player = null

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: ColorRect = $ColorRect
@onready var _prompt_top: Label = $PromptTop
@onready var _prompt_bottom: Label = $PromptBottom


func _ready() -> void:
	_apply_size()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _player == null:
		return
	# 玩家在梯子中点上方 → 显示顶端提示，否则显示底端提示
	var mid_y := global_position.y - height * 0.5
	var near_top: bool = _player.global_position.y < mid_y
	_prompt_top.visible = near_top
	_prompt_bottom.visible = not near_top


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
	_prompt_top.offset_top = -height - 12.0
	_prompt_top.offset_bottom = -height


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player = body as Player
		_player.enter_ladder()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).exit_ladder()
		_player = null
		_prompt_top.visible = false
		_prompt_bottom.visible = false
