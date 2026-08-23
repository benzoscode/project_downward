extends Area2D
## 告示牌：玩家靠近即显示牌面文本（世界内 Label），离开消失；字体已调小。
## 用于机制提示，如光敏宝石旁"用灯照射"的引导（2026-08-17 用户需求）。

## 告示内容（支持多行）
@export_multiline var text: String = ""
## 牌子外观（木牌/石碑两套正式素材；缺省木牌）
@export var sign_texture: Texture2D

@onready var _text_label: Label = $TextLabel
@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_sprite.texture = sign_texture if sign_texture != null else preload("res://assets/props/sign_wood.png")
	_text_label.text = text
	_text_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		if not text.is_empty():
			_text_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_text_label.visible = false
