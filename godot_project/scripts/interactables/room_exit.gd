@tool
extends Area2D
## 房间出口积木（M8）：玩家进入触发区 → RoomManager 切换到目标场景入口。
## 连线：target_scene 在 Inspector 里直接选 .tscn 文件（文件选择器，无需手敲路径）；
## target_entrance 对应对面场景的 Entrance_<id> 标记，缺省 default。
## 门控由实体机关（石门/钥匙门）负责，本积木不管。

## 目标场景文件（Inspector 文件选择器选取）
@export_file("*.tscn") var target_scene: String:
	set(value):
		target_scene = value
		queue_redraw()
## 目标入口 ID（对面对应 Entrance_<id> 标记；default 可省略）
@export var target_entrance: StringName = &"default":
	set(value):
		target_entrance = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	if target_scene.is_empty():
		push_warning("room_exit 未配置 target_scene")
		return
	RoomManager.goto_room(target_scene, target_entrance)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	# 出口可视化：青色描边 + 目标文字（策划在编辑器一眼看清连线）
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var half := Vector2(8, 24)
	if shape_node != null and shape_node.shape is RectangleShape2D:
		half = (shape_node.shape as RectangleShape2D).size / 2.0
	var rect := Rect2(-half, half * 2.0)
	draw_rect(rect, Color(0.3, 0.9, 1.0, 0.15), true)
	draw_rect(rect, Color(0.3, 0.9, 1.0, 0.8), false, 1.5)
	var scene_label := target_scene
	if scene_label.begins_with("uid://"): # 编辑器可能存 uid 引用，显示时解析回文件名
		var uid: int = ResourceUID.text_to_id(scene_label)
		if ResourceUID.has_id(uid):
			scene_label = ResourceUID.get_id_path(uid)
	var label := "→ " + scene_label.get_file().get_basename()
	if target_entrance != &"default":
		label += ":" + String(target_entrance)
	draw_string(ThemeDB.fallback_font, Vector2(-half.x, -half.y - 6.0),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 0.9, 1.0, 0.9))


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
