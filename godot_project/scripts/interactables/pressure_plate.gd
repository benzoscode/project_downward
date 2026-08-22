extends Area2D
## 压力板（M5）：踩下触发 target_id，离开解除。
## mouse_only=true 为小型板（仅老鼠可踩）；false 为大型板（人鼠皆可）。

@export var target_id: StringName
## true=小型（仅老鼠），false=大型（玩家与老鼠皆可）
@export var mouse_only: bool = true

var _pressers: int = 0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _tex_up: Texture2D = preload("res://assets/props/plate_up.png")
@onready var _tex_down: Texture2D = preload("res://assets/props/plate_down.png")


func _ready() -> void:
	var size := Vector2(8, 6) if mouse_only else Vector2(16, 6)
	(_collision.shape as RectangleShape2D).size = size
	# 正式素材单尺寸 16×16（2026-08-20）：小型板不缩放，仅判定更小（用户拍板）
	_sprite.texture = _tex_up
	_sprite.scale = Vector2.ONE
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# 死亡重生不重置：总线已触发则保持按下视觉
	if MechanismBus.is_triggered(target_id):
		_sprite.texture = _tex_down


func _is_allowed(body: Node2D) -> bool:
	if mouse_only:
		return body.is_in_group(&"mouse")
	return body.is_in_group(&"mouse") or body.is_in_group(&"player")


func _on_body_entered(body: Node2D) -> void:
	if not _is_allowed(body):
		return
	_pressers += 1
	if _pressers == 1:
		MechanismBus.trigger(target_id)
		_sprite.texture = _tex_down
		Sfx.play(&"plate_press")


func _on_body_exited(body: Node2D) -> void:
	if not _is_allowed(body):
		return
	_pressers = maxi(0, _pressers - 1)
	if _pressers == 0:
		MechanismBus.release(target_id)
		_sprite.texture = _tex_up
