extends Area2D
## 告示牌：玩家靠近即显示牌面文本（世界内 Label），离开消失。
## 文字放在 CanvasLayer 上，不受房间暗度（CanvasModulate）影响，始终可读。

## 告示内容（支持多行）
@export_multiline var text: String = ""
## 牌子外观（木牌/石碑两套正式素材；缺省木牌）
@export var sign_texture: Texture2D

@onready var _text_layer: CanvasLayer = $TextLayer
@onready var _text_label: Label = $TextLayer/TextLabel
@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_sprite.texture = sign_texture if sign_texture != null else preload("res://assets/props/sign_wood.png")
	# 小像素下字号 6 太细、放大发虚：加大字号并加黑描边，保证清晰可读
	var ls := LabelSettings.new()
	ls.font_size = 9
	ls.font_color = Color(1, 1, 1, 1)
	ls.outline_size = 2
	ls.outline_color = Color(0, 0, 0, 0.9)
	_text_label.label_settings = ls
	_text_label.text = text
	_text_label.visible = false
	# 文字层跟随视口：子节点坐标即世界坐标，随镜头移动，且不受房间暗度(CanvasModulate)影响
	_text_layer.follow_viewport_enabled = true
	# 锚定到牌子正上方的世界坐标（牌子静止，设定一次即可）；字号加大后抬高留足高度
	var base := global_position
	_text_label.offset_left = base.x - 42.0
	_text_label.offset_top = base.y - 60.0
	_text_label.offset_right = base.x + 42.0
	_text_label.offset_bottom = base.y - 14.0
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		if not text.is_empty():
			_text_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_text_label.visible = false
