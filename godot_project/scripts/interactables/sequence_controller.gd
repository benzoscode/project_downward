extends Node2D
## 水滴顺序机关控制器（M6，策划案 §三(二)）：
## 彩色按钮按 expected 顺序按下 → 广播 target_id；按错 → 进度清零重来。

## 序列 ID：按钮通过组 seq_<id> 找到本控制器；支持运行时改 ID（重新注册组）
@export var sequence_id: StringName:
	set(value):
		if is_inside_tree() and sequence_id != &"":
			remove_from_group(&"seq_" + sequence_id)
		sequence_id = value
		if is_inside_tree() and value != &"":
			add_to_group(&"seq_" + value)
## 期望的颜色序列
@export var expected: Array[StringName] = []
## 完成后广播的机关 ID
@export var target_id: StringName

var _progress: int = 0


func _ready() -> void:
	add_to_group(&"seq_" + sequence_id)


func register_press(color_id: StringName) -> void:
	if _progress >= expected.size():
		return
	if color_id == expected[_progress]:
		_progress += 1
		if _progress == expected.size():
			MechanismBus.trigger(target_id)
	else:
		_progress = 0 # 按错重来


## 验证脚本用
func get_progress() -> int:
	return _progress
