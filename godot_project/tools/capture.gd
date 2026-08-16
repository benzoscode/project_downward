extends SceneTree
## 截图工具：加载指定场景运行若干帧后保存 PNG，供人类审阅。
## 用法（在 godot_project/ 下，窗口移到屏幕外避免干扰）：
##   & <godot_console.exe> --script tools/capture.gd --position -2000,100 -- res://scenes/rooms/demo_room.tscn 30 shot.png [bright]
## 可选第 4 参数 "bright"：截图时把房间亮度切到编辑器亮度，便于审阅布局。

var _scene_path: String = ""
var _frames: int = 30
var _output: String = ""
var _bright: bool = false
var _elapsed: int = 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		printerr("usage: capture.gd <scene_path> <frames> <output.png> [bright]")
		quit(1)
		return
	_scene_path = args[0]
	_frames = int(args[1])
	_output = args[2]
	_bright = args.size() >= 4 and args[3] == "bright"
	var packed := load(_scene_path) as PackedScene
	if packed == null:
		printerr("cannot load scene: ", _scene_path)
		quit(1)
		return
	var instance := packed.instantiate()
	if _bright:
		# 编辑器亮度（room_base.gd 的默认值），用于布局审阅截图
		var modulate := instance.get_node_or_null("CanvasModulate") as CanvasModulate
		if modulate != null:
			modulate.color = Color(0.45, 0.45, 0.45, 1)
	root.add_child(instance)


func _process(_delta: float) -> bool:
	_elapsed += 1
	if _elapsed >= _frames:
		var img := root.get_texture().get_image()
		var err := img.save_png(_output)
		if err != OK:
			printerr("save_png failed: ", error_string(err))
		else:
			print("screenshot saved: ", _output)
		return true
	return false
