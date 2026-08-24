extends Control
## 结局画面（2026-08-24）：结局图 + 半透明黑底 + 白色旁白逐段显现。
## 进入结局后不暂停、不停 BGM（Music 为 Autoload 常驻，换场景持续循环），
## 诗句按段落自动推进；可点击 / 空格 快进。全部播完后显示"返回主菜单"。

## 结局旁白（逐段显示，每段停顿后自动切换）
const LINES: Array[String] = [
	"地底的旅程或许暂时结束了......",
	"你走出洞口，心底满是逃出生天的庆幸",
	"有种东西很刺眼，让你下意识的抬手遮住眼睛",
	"那不是灯光，不是荧光，是阳光",
	"你站在洞口，风吹过你的脸",
	"你想起那只小老鼠",
	"你把骨质小哨握在掌心，吹了一声",
	"没有回应",
	"哨声散在风里，像一滴水落入湖中",
	"你没有回头",
	"你关掉了灯",
	"这一次，你不需要它了",
	"继续前行吧，勇敢的探险者！",
]

## 每段显示节奏（秒）：淡入 → 停留 → 淡出
const FADE_IN := 0.4
const HOLD := 2.6
const FADE_OUT := 0.4

@onready var _line_label: Label = $TextLabel
@onready var _restart_button: Button = $Center/VBox/RestartButton

var _index: int = 0
var _tween: Tween


func _ready() -> void:
	_line_label.modulate.a = 0.0
	_line_label.visible = true
	_restart_button.visible = false
	_restart_button.modulate.a = 0.0
	_restart_button.pressed.connect(_on_restart_pressed)
	_play_line(0)


func _play_line(i: int) -> void:
	_index = i
	_line_label.text = LINES[i]
	_line_label.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_line_label, "modulate:a", 1.0, FADE_IN)
	_tween.tween_interval(HOLD)
	_tween.tween_property(_line_label, "modulate:a", 0.0, FADE_OUT)
	_tween.tween_callback(_advance)


func _advance() -> void:
	if _index + 1 < LINES.size():
		_play_line(_index + 1)
	else:
		_finish()


func _finish() -> void:
	# 全部播完：清空旁白，浮现返回按钮
	_line_label.visible = false
	_restart_button.visible = true
	_restart_button.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_restart_button, "modulate:a", 1.0, 0.5)
	_restart_button.grab_focus()


func _skip() -> void:
	if _index >= LINES.size():
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		_skip()


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
