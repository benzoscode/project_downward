extends Area2D
## 通用道具拾取物：玩家触碰即获得，写入 GameState（策划案 §二(二)：道具永久持有）。
## item 取值：lamp / boots / whistle / gem_jade / gem_amber / gem_violet。

const ICONS: Dictionary = {
	&"lamp": preload("res://assets/placeholder/item_lamp.png"),
	&"boots": preload("res://assets/placeholder/item_boots.png"),
	&"whistle": preload("res://assets/placeholder/item_whistle.png"),
	&"gem_jade": preload("res://assets/placeholder/item_gem_jade.png"),
	&"gem_amber": preload("res://assets/placeholder/item_gem_amber.png"),
	&"gem_violet": preload("res://assets/placeholder/item_gem_violet.png"),
}

@export var item: StringName = &"lamp":
	set(value):
		item = value
		_update_icon()

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_icon()


func _update_icon() -> void:
	if not is_node_ready():
		return
	var icon: Texture2D = ICONS.get(item)
	if icon != null:
		_sprite.texture = icon


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		GameState.acquire_item(item)
		queue_free()
