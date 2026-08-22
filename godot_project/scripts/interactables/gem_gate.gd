extends AnimatableBody2D
## 三宝石门（2026-08-20 新增，策划案 §房间12 三宝石之门简化版）：门上三个宝石凹槽，
## 玩家靠近按 E 将身上一颗宝石镶嵌到对应凹槽；翡翠/琥珀/紫金三颗全部镶嵌后大门上升开启。
## 镶嵌顺序由 socket_order 决定（默认翡翠→琥珀→紫金），与策划案刻痕顺序一致。
## 状态持久化：每个 socket 用 MechanismBus 标记（<gate_id>_<gem>），死亡重生/跨房间后仍能复原（§一）。

const GEM_TEX: Dictionary = {
	&"jade": {"tex": "res://assets/props/door_gem_jade.png", "empty": "res://assets/props/door_gem_jade_empty.png"},
	&"amber": {"tex": "res://assets/props/door_gem_amber.png", "empty": "res://assets/props/door_gem_amber_empty.png"},
	&"violet": {"tex": "res://assets/props/door_gem_violet.png", "empty": "res://assets/props/door_gem_violet_empty.png"},
}
const GEM_NAMES: Dictionary = {
	&"jade": &"gem_jade",
	&"amber": &"gem_amber",
	&"violet": &"gem_violet",
}

@export_group("连线")
## 本门的持久化 ID（每个门唯一）；socket 状态写 <gate_id>_<宝石>
@export var gate_id: StringName = &"gem_gate_1"
## 镶嵌顺序（对应三个凹槽，从左到右），策划案刻痕顺序 翡翠→琥珀→紫金
@export var socket_order: Array[StringName] = [&"jade", &"amber", &"violet"]
## 全部镶嵌后额外广播的机关 ID（可选，用于联动其它机关）
@export var open_emit_id: StringName = &""
## 开门动画时长（秒）
@export var tween_duration: float = 0.5

var _is_open: bool = false
var _closed_y: float
var _tween: Tween = null
var _socket_sprites: Array[Sprite2D] = []

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _prompt: Label = $Prompt


func is_open() -> bool:
	return _is_open


func _ready() -> void:
	_closed_y = position.y
	add_to_group(&"interactable")
	_socket_sprites.clear()
	for child in $Sockets.get_children():
		_socket_sprites.append(child as Sprite2D)
	for i in range(_socket_sprites.size()):
		var gem: StringName = socket_order[i] if i < socket_order.size() else socket_order[0]
		_apply_socket(i, gem)
	var zone := $InteractZone as Area2D
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	_apply_open_state(_all_filled(), true)


## 便捷：判断玩家是否持有某宝石（供策划/脚本查询）
func player_has_gem(gem: StringName) -> bool:
	return GameState.gems.has(GEM_NAMES[gem])


func interact() -> void:
	if _is_open:
		return
	for i in range(_socket_sprites.size()):
		var gem: StringName = socket_order[i] if i < socket_order.size() else socket_order[0]
		if _socket_triggered(i):
			continue
		if GameState.gems.has(GEM_NAMES[gem]):
			_embed(i, gem)
	if _all_filled():
		_apply_open_state(true, false)
		Sfx.play(&"gate_open")
		if open_emit_id != &"":
			MechanismBus.trigger(open_emit_id)
		return


func _socket_id(i: int) -> StringName:
	var gem: StringName = socket_order[i] if i < socket_order.size() else socket_order[0]
	return StringName(String(gate_id) + "_" + String(GEM_NAMES[gem]))


func _socket_triggered(i: int) -> bool:
	return MechanismBus.is_triggered(_socket_id(i))


func _all_filled() -> bool:
	for i in range(_socket_sprites.size()):
		if not _socket_triggered(i):
			return false
	return not _socket_sprites.is_empty()


func _embed(i: int, gem: StringName) -> void:
	MechanismBus.trigger(_socket_id(i))
	GameState.gems.erase(GEM_NAMES[gem])
	_apply_socket(i, gem)
	Sfx.play(&"gem_embed")


func _apply_socket(i: int, gem: StringName) -> void:
	var sprite := _socket_sprites[i] as Sprite2D
	if sprite == null:
		return
	var filled := _socket_triggered(i)
	var info: Dictionary = GEM_TEX[gem]
	sprite.texture = load(info["tex"] if filled else info["empty"])


func _apply_open_state(open: bool, instant: bool) -> void:
	if _is_open == open and not instant:
		return
	_is_open = open
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var target_y := _closed_y - 48.0 if open else _closed_y
	if instant:
		position.y = target_y
	else:
		_tween = create_tween()
		_tween.tween_property(self, "position:y", target_y, tween_duration)
	_collision.set_deferred("disabled", open)
	if open:
		_prompt.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).set_interactable(self)
		if not _is_open:
			_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).clear_interactable(self)
		_prompt.visible = false
