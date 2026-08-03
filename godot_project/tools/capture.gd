extends SceneTree
## 截图工具：加载指定场景运行若干帧后保存 PNG，供人类审阅。
## 用法（在 godot_project/ 下，窗口移到屏幕外避免干扰）：
##   & <godot_console.exe> --script tools/capture.gd --position -2000,100 -- res://scenes/templates/room_base.tscn 30 shot.png

var _scene_path: String = ""
var _frames: int = 30
var _output: String = ""
var _elapsed: int = 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		printerr("usage: capture.gd <scene_path> <frames> <output.png>")
		quit(1)
		return
	_scene_path = args[0]
	_frames = int(args[1])
	_output = args[2]
	var packed := load(_scene_path) as PackedScene
	if packed == null:
		printerr("cannot load scene: ", _scene_path)
		quit(1)
		return
	root.add_child(packed.instantiate())


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
