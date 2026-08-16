extends Area2D
## 宝箱：玩家靠近按 E 开启，直接发放道具到 GameState，一次性。

@export var item: StringName = &"lamp"

var _opened: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _prompt: Label = $Prompt
@onready var _tex_open: Texture2D = preload("res://assets/placeholder/chest_wood_open.png")


func _ready() -> void:
	add_to_group(&"interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func interact() -> void:
	if _opened:
		return
	_opened = true
	_sprite.texture = _tex_open
	_prompt.visible = false
	GameState.acquire_item(item)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).set_interactable(self)
		if not _opened:
			_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).clear_interactable(self)
		_prompt.visible = false
