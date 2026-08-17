@tool
extends Area2D
## 检查点积木（M8 补充）：玩家触碰即存档（当前房间 + 本点坐标），死亡后回这里。
## 用于房间中部的存档位（第 8 房刺坑阵、第 12 房第二层入口等，策划案 §三(十二)）。
## 无需配置：场景路径自动取 RoomManager.current_room_id（scene_file_path）。

## 触碰后的视觉反馈色（占位，未来换正式素材）
const ACTIVATED_TINT := Color(1.0, 0.85, 0.3)

var _activated := false

@onready var _pole: ColorRect = $Pole


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	GameState.set_checkpoint(RoomManager.current_room_id, global_position)
	if not _activated:
		_activated = true
		_pole.color = ACTIVATED_TINT


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	# 编辑器可视化：金色虚线圈标出触发范围
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node != null and shape_node.shape is RectangleShape2D:
		var half := (shape_node.shape as RectangleShape2D).size / 2.0
		draw_rect(Rect2(-half, half * 2.0), Color(1.0, 0.85, 0.3, 0.5), false, 1.0)
