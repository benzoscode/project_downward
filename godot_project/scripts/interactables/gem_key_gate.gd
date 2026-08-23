extends AnimatableBody2D
## 宝石钥匙门（2026-08-23 需求）：玩家靠近检测是否持有全部三颗宝石（翡翠/琥珀/紫金），
## 集齐则开启，否则不开启。与 gem_gate（镶嵌消耗）不同：本门只作"钥匙校验"，不消耗宝石、不嵌入。
## 机关门面用石门素材；开门后保持开启（持久化用 gate_id）。

const REQUIRED: Array[StringName] = [&"gem_jade", &"gem_amber", &"gem_violet"]

@export_group("连线")
## 本门持久化 ID（开门后保持）
@export var gate_id: StringName = &"gem_key_gate_1"
## 开门动画时长（秒）
@export var tween_duration: float = 0.5

var _is_open: bool = false
var _closed_y: float
var _tween: Tween = null

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _prompt: Label = $Prompt


func is_open() -> bool:
	return _is_open


## 是否已集齐三颗宝石
func has_all_gems() -> bool:
	for gem in REQUIRED:
		if not GameState.gems.has(gem):
			return false
	return true


func _ready() -> void:
	_closed_y = position.y
	add_to_group(&"interactable")
	var zone := $InteractZone as Area2D
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	# 重生恢复：已开过（gate_id 总线标记）或已集齐 → 直接开
	_apply_open_state(MechanismBus.is_triggered(gate_id) or has_all_gems(), true)


func interact() -> void:
	if _is_open:
		return
	if has_all_gems():
		_apply_open_state(true, false)
		MechanismBus.trigger(gate_id)
		Sfx.play(&"gate_open")
	else:
		# 未集齐：提示 + 交互音
		Sfx.play(&"interact")
		HUD.show_message("三颗宝石集齐才能开启…")


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
