extends Area2D
## 狮子头按钮：玩家靠近按 E（interact）触发，通过 MechanismBus 广播 target_id。
## one_shot=false 时可重复按（在开/关间切换）；true 时只触发一次。

@export var target_id: StringName
## 一次性按钮：触发后不再响应
@export var one_shot: bool = false

var _pressed: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _tex_up: Texture2D = preload("res://assets/placeholder/prop_button_up.png")
@onready var _tex_down: Texture2D = preload("res://assets/placeholder/prop_button_down.png")


func _ready() -> void:
	add_to_group(&"interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# 死亡重生不重置按钮（策划案 §一）：若总线已是触发态，同步视觉
	if one_shot and MechanismBus.is_triggered(target_id):
		_pressed = true
		_sprite.texture = _tex_down


func interact() -> void:
	if one_shot and _pressed:
		return
	_pressed = not _pressed
	if _pressed:
		MechanismBus.trigger(target_id)
	else:
		MechanismBus.release(target_id)
	_sprite.texture = _tex_down if _pressed else _tex_up


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).set_interactable(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).clear_interactable(self)
