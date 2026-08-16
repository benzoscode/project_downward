extends AnimatableBody2D
## 石门：监听 MechanismBus 的 listen_id，触发开 / 解除关。
## start_open=true 为常开门（此时信号反转：触发关门）。
## 死亡重生后由 is_triggered 恢复门态，满足策划案 §一"机关状态保留"。

@export var listen_id: StringName
@export var start_open: bool = false
## 开门动画时长（秒）
@export var tween_duration: float = 0.4

var _is_open: bool = false
var _closed_y: float
var _tween: Tween = null

@onready var _collision: CollisionShape2D = $CollisionShape2D


func is_open() -> bool:
	return _is_open


func _ready() -> void:
	_closed_y = position.y
	MechanismBus.triggered.connect(_on_triggered)
	MechanismBus.released.connect(_on_released)
	# 初始态：常开 或 总线已触发 → 直接到位，不播动画
	var should_open := start_open != MechanismBus.is_triggered(listen_id)
	if should_open:
		_apply_open_state(true, true)


func _on_triggered(id: StringName) -> void:
	if id == listen_id:
		_apply_open_state(not start_open, false)


func _on_released(id: StringName) -> void:
	if id == listen_id:
		_apply_open_state(start_open, false)


func _apply_open_state(open: bool, instant: bool) -> void:
	if _is_open == open and not instant:
		return
	_is_open = open
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var target_y := _closed_y - 48.0 if open else _closed_y # 门高 3 格，见 §7 尺寸表
	if instant:
		position.y = target_y
	else:
		_tween = create_tween()
		_tween.tween_property(self, "position:y", target_y, tween_duration)
	# 开门后关碰撞；关门动画开始就恢复碰撞，防止玩家卡进门缝
	_collision.set_deferred("disabled", open)
