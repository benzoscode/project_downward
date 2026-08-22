extends Area2D
## 告示牌：玩家靠近按 E 查看文字（经 HUD 弹窗显示）。
## 用于机制提示，如光敏宝石旁"用灯照射"的引导（2026-08-17 用户需求）。

## 告示内容（支持多行）
@export_multiline var text: String = ""
## 牌子外观（2026-08-20：木牌/石碑两套正式素材；场景可在 Inspector 指定，缺省木牌）
@export var sign_texture: Texture2D

@onready var _prompt: Label = $Prompt
@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_sprite.texture = sign_texture if sign_texture != null else preload("res://assets/props/sign_wood.png")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## 玩家 E 交互时调用（player._interactable 协议）
func interact() -> void:
	Sfx.play(&"interact")
	if not text.is_empty():
		HUD.show_message(text)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).set_interactable(self)
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).clear_interactable(self)
		_prompt.visible = false
