extends AnimatableBody2D
## 双按钮门（M6）：listen_ids 全部处于触发态才开门；任一解除后延迟 2 秒关闭。
## 策划案 §三(八)：松手延迟关闭给玩家通过窗口。

## 需要同时触发的一组机关 ID（通常两个按钮/压力板）
@export var listen_ids: Array[StringName] = []
## 失去触发后多少秒关闭
@export var close_delay: float = 2.0
## 开门动画时长（秒）
@export var tween_duration: float = 0.4
## 打开后保持开启：一旦全触发开启就不再关闭（双压力板门用，2026-08-23 需求）
@export var latch_open: bool = false

var _is_open: bool = false
var _closed_y: float
var _close_timer: float = -1.0 # >=0 表示正在倒计时关闭
var _tween: Tween = null

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_closed_y = position.y
	MechanismBus.triggered.connect(_on_changed.unbind(1))
	MechanismBus.released.connect(_on_changed.unbind(1))
	# 重生恢复：已触发则直接开（latch 门一旦开就不关）
	if _all_triggered() or _latch_was_open():
		_apply_open(true, true)


func _physics_process(delta: float) -> void:
	if _close_timer >= 0.0:
		_close_timer -= delta
		if _close_timer < 0.0:
			_apply_open(false, false)


func _on_changed() -> void:
	# latch：开过就不再关
	if _is_open and latch_open:
		return
	if _all_triggered():
		_close_timer = -1.0
		_apply_open(true, false)
	elif _is_open:
		_close_timer = close_delay


## latch 门状态持久化：用 listen_ids 首元素记住"已开过"
func _latch_was_open() -> bool:
	return latch_open and not listen_ids.is_empty() and MechanismBus.is_triggered(listen_ids[0])


func _all_triggered() -> bool:
	for id in listen_ids:
		if not MechanismBus.is_triggered(id):
			return false
	return not listen_ids.is_empty()


func _apply_open(open: bool, instant: bool) -> void:
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
	Sfx.play(&"door_open" if open else &"door_close")


func is_open() -> bool:
	return _is_open
