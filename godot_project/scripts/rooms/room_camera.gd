extends Camera2D
class_name RoomCamera
## 房间相机：平滑跟随玩家，受 room_base 模板中的 limit 约束。
## 相机放在房间而非玩家身上，是因为相界属于房间数据（策划按房间调整）。

## 跟随目标所在的组名；M5 切换老鼠操控时会改为跟随老鼠
@export var follow_group: StringName = &"player"


func _ready() -> void:
	enabled = true


func _physics_process(_delta: float) -> void:
	var targets := get_tree().get_nodes_in_group(follow_group)
	if targets.is_empty():
		return
	var target := targets[0] as Node2D
	if target != null:
		global_position = target.global_position
