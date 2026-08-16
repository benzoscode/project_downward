extends SceneTree
func _initialize() -> void:
	var instance := (load("res://scenes/rooms/demo_room.tscn") as PackedScene).instantiate()
	root.add_child(instance)
	var modulate := instance.get_node_or_null("CanvasModulate") as CanvasModulate
	print("after add_child: ", modulate.color)
	modulate.color = Color(0.45, 0.45, 0.45, 1)
	print("after override: ", modulate.color)
func _process(_d: float) -> bool:
	if Engine.get_process_frames() == 30:
		var modulate := root.get_node("RoomBase/CanvasModulate") as CanvasModulate
		print("at frame 30: ", modulate.color)
		return true
	return false