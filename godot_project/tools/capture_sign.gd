extends Node
## 告示牌弹窗截图验证：触发 HUD.show_message 多行文字，截图确认完整显示。
## 用法：& <godot_console.exe> res://scenes/test/verify_host.tscn --position -2000,100 -- res://tools/capture_sign.gd


func _ready() -> void:
	_run()


func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	HUD.show_message("一块字迹模糊的石碑：\n『以光唤醒宝石，门自会开启。』", 10.0)
	for i in range(10):
		await get_tree().process_frame
	var path := "res://tools/out/sign_toast.png"
	if get_tree().root.get_texture().get_image().save_png(path) == OK:
		print("screenshot saved: ", path)
	get_tree().quit(0)
