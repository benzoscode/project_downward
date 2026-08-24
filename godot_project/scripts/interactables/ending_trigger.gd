@tool
extends Area2D
## 结局触发（临时占位，M9 前）：玩家进入即切换到结局画面。
## 不走 RoomManager（结局是独立 UI 场景，非房间），直接 change_scene_to_file。
## M9 终局建成后由正式流程取代此积木。


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	get_tree().change_scene_to_file("res://scenes/ui/ending.tscn")


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var half := Vector2(8, 24)
	if shape_node != null and shape_node.shape is RectangleShape2D:
		half = (shape_node.shape as RectangleShape2D).size / 2.0
	var rect := Rect2(-half, half * 2.0)
	draw_rect(rect, Color(0.55, 0.3, 0.95, 0.18), true)
	draw_rect(rect, Color(0.55, 0.3, 0.95, 0.9), false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(-half.x, -half.y - 6.0),
		"结局", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.55, 0.3, 0.95, 0.95))


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
