extends Node2D
## 机关滞后组件（M6）：input_id 触发后延迟 N 秒才触发 output_id（如石桥延迟升起）。
## 解除立即传递（不延迟）。重复触发会重置倒计时。纯逻辑积木，无视觉。

@export var input_id: StringName
@export var output_id: StringName
## 延迟秒数
@export var delay: float = 1.0

var _pending: float = -1.0


func _ready() -> void:
	MechanismBus.triggered.connect(_on_triggered)
	MechanismBus.released.connect(_on_released)


func _physics_process(delta: float) -> void:
	if _pending >= 0.0:
		_pending -= delta
		if _pending < 0.0:
			MechanismBus.trigger(output_id)


func _on_triggered(id: StringName) -> void:
	if id == input_id:
		_pending = delay


func _on_released(id: StringName) -> void:
	if id == input_id:
		_pending = -1.0
		MechanismBus.release(output_id)
