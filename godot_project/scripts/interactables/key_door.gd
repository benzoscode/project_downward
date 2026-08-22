extends AnimatableBody2D
## 钥匙门（M8）：持有钥匙（GameState.has_key，第 4 房间宝箱获取）才开启。
## 策划案 §三(三)：第 3 房间右上角门，通往第 12 房间。与石门同规格（32×48，开门上移 3 格）。

## 开门动画时长（秒）
@export var tween_duration: float = 0.6

var _is_open: bool = false
var _closed_y: float
var _tween: Tween = null

@onready var _collision: CollisionShape2D = $CollisionShape2D


func is_open() -> bool:
	return _is_open


func _ready() -> void:
	_closed_y = position.y
	GameState.item_acquired.connect(_on_item_acquired)
	# 重生/回房间恢复：已持钥匙则直接开到位（道具永久持有，§二(二)）
	if GameState.has_key:
		_apply_open(true)


func _on_item_acquired(item: StringName) -> void:
	if item == &"key":
		_apply_open(false)


func _apply_open(instant: bool) -> void:
	if _is_open:
		return
	_is_open = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var target_y := _closed_y - 48.0
	if instant:
		position.y = target_y
	else:
		_tween = create_tween()
		_tween.tween_property(self, "position:y", target_y, tween_duration)
	_collision.set_deferred("disabled", true)
	Sfx.play(&"door_open")
