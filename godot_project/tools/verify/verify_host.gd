extends Node
## 验证脚本宿主：以真实场景身份运行（Autoload 可用），把命令行参数指定的
## 验证脚本挂为子节点执行。退出码由验证脚本自行 get_tree().quit(code)。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_mechanisms.gd


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage: verify_host.tscn -- <verify_script_path>")
		get_tree().quit(1)
		return
	var script := load(args[0]) as GDScript
	if script == null:
		printerr("cannot load verify script: ", args[0])
		get_tree().quit(1)
		return
	var node := Node.new()
	node.set_script(script)
	add_child(node)
