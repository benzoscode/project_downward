@tool
extends Node2D
class_name RoomBase
## 房间根节点：编辑器显示亮度与运行时黑暗分离。
## 搭建时策划需要看清地形，运行时要近全黑（策划案 §二(二)1 关灯视野）。
## M2 实现照明灯后，游戏内黑暗由灯光系统与 CanvasModulate 共同作用。

## 编辑器显示亮度（搭建用，仅编辑器生效）
@export_color_no_alpha var editor_brightness: Color = Color(0.45, 0.45, 0.45)
## 运行时黑暗亮度（游戏用）
@export_color_no_alpha var game_darkness: Color = Color(0.05, 0.06, 0.09)


func _enter_tree() -> void:
	var modulate := get_node_or_null("CanvasModulate") as CanvasModulate
	if modulate == null:
		return
	if Engine.is_editor_hint():
		modulate.color = editor_brightness
	else:
		modulate.color = game_darkness
