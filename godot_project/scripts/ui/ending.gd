extends Control
## 游戏结束画面（2026-08-23）：通关成就 + 重新开始按钮（结局流程 M9 接入）。

@onready var _restart_button: Button = $Center/VBox/RestartButton


func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_pressed)
	_restart_button.grab_focus()


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
