extends Area2D
## 狮子头按钮：玩家靠近按 E（interact）触发，通过 MechanismBus 广播 target_id。
## one_shot=false 时可重复按（在开/关间切换）；true 时只触发一次。

@export var target_id: StringName
## 一次性按钮：触发后不再响应
@export var one_shot: bool = false
## 点动模式：每按一次都广播一次 trigger（不切换、不 release），配发射器等"按一次发一次"的机关
@export var momentary: bool = false

var _pressed: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _prompt: Label = $Prompt
@onready var _tex_up: Texture2D = preload("res://assets/props/button_base.png")
# 正式素材无按下差分（2026-08-20），按下态=同图+压暗
@onready var _tex_down: Texture2D = _tex_up


func _ready() -> void:
	add_to_group(&"interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# 死亡重生不重置按钮（策划案 §一）：若总线已是触发态，同步视觉
	if one_shot and MechanismBus.is_triggered(target_id):
		_pressed = true
		_sprite.texture = _tex_down
		_sprite.modulate = Color(0.7, 0.7, 0.7)


func interact() -> void:
	if momentary:
		# 点动：每次按都发脉冲（不存状态、不切换），弹起视觉即时恢复
		MechanismBus.pulse(target_id)
		_sprite.texture = _tex_down
		_sprite.modulate = Color(0.7, 0.7, 0.7)
		var tween := create_tween()
		tween.tween_interval(0.12)
		tween.tween_callback(func() -> void:
			_sprite.texture = _tex_up
			_sprite.modulate = Color.WHITE)
		return
	if one_shot and _pressed:
		return
	_pressed = not _pressed
	if _pressed:
		MechanismBus.trigger(target_id)
	else:
		MechanismBus.release(target_id)
	_sprite.texture = _tex_down if _pressed else _tex_up
	_sprite.modulate = Color(0.7, 0.7, 0.7) if _pressed else Color.WHITE
	if one_shot and _pressed:
		_prompt.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).set_interactable(self)
		if not (one_shot and _pressed):
			_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).clear_interactable(self)
		_prompt.visible = false
