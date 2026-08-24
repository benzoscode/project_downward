extends Control
## 游戏开始界面（2026-08-23）：标题 + 开始游戏按钮。

@onready var _start_button: Button = $Center/VBox/StartButton


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_start_button.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
