extends Area2D
## 彩色按钮（水滴顺序机关的输入端，M6）：E 按下后向 sequence_id 控制器上报 color_id。
## 与狮子头按钮的区别：不参与 MechanismBus，只进序列判定。

## 按钮颜色 ID（如 red/green/blue），仅用于序列匹配与着色
@export var color_id: StringName = &"red":
	set(value):
		color_id = value
		_apply_tint()
## 所属序列控制器 ID
@export var sequence_id: StringName

const COLORS: Dictionary = {
	&"red": Color(0.9, 0.35, 0.3),
	&"green": Color(0.4, 0.85, 0.45),
	&"blue": Color(0.35, 0.55, 0.95),
	&"amber": Color(0.95, 0.75, 0.3),
}
# 正式按钮素材（2026-08-20/23）：四色齐全——绿/红/蓝/黄（琥珀）。
# 绿色即 button_base（2026-08-23 策划确认：四张颜色钮文件，此前误判 base 为通用）
const TEXTURES: Dictionary = {
	&"red": preload("res://assets/props/button_red.png"),
	&"blue": preload("res://assets/props/button_blue.png"),
	&"amber": preload("res://assets/props/button_yellow.png"),
	&"green": preload("res://assets/props/button_base.png"),
}

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _prompt: Label = $Prompt


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_apply_tint()


func _apply_tint() -> void:
	if not is_node_ready():
		return
	if TEXTURES.has(color_id):
		_sprite.texture = TEXTURES[color_id]
		_sprite.modulate = Color.WHITE
	else:
		_sprite.modulate = COLORS.get(color_id, Color.WHITE)


func interact() -> void:
	var controller := get_tree().get_first_node_in_group(&"seq_" + sequence_id)
	if controller != null and controller.has_method("register_press"):
		controller.register_press(color_id)
	# 按压反馈
	_sprite.scale = Vector2(0.85, 0.85)
	create_tween().tween_property(_sprite, "scale", Vector2.ONE, 0.15)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).set_interactable(self)
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).clear_interactable(self)
		_prompt.visible = false
