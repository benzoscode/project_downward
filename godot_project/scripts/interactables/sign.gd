extends Area2D
## 告示牌：玩家靠近按 E 查看文字（经 HUD 弹窗显示）。
## 用于机制提示，如光敏宝石旁"用灯照射"的引导（2026-08-17 用户需求）。

## 告示内容（支持多行）
@export_multiline var text: String = ""

@onready var _prompt: Label = $Prompt


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## 玩家 E 交互时调用（player._interactable 协议）
func interact() -> void:
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
