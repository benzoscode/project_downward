extends Area2D
## 遗物台（2026-08-23 需求）：地面石台 + 其上方悬浮的道具/宝石（上下浮动 + 发光），玩家触碰即拾取。
## 取代原宝箱积木：道具以自身美术素材展示在遗物台上，无需按 E。
## item 取值：lamp / boots / whistle / key / gem_jade / gem_amber / gem_violet。

const ICONS: Dictionary = {
	&"lamp": preload("res://assets/props/item_lamp.png"),
	&"boots": preload("res://assets/props/item_boots.png"),
	&"whistle": preload("res://assets/props/item_whistle.png"),
	&"key": preload("res://assets/props/item_key.png"),
	&"gem_jade": preload("res://assets/props/item_gem_jade.png"),
	&"gem_amber": preload("res://assets/props/item_gem_amber.png"),
	&"gem_violet": preload("res://assets/props/item_gem_violet.png"),
}
# 各道具的展示光颜色（宝石按颜色，道具统一暖白光）
const GLOW_COLORS: Dictionary = {
	&"lamp": Color(1.0, 0.7, 0.35),
	&"boots": Color(0.75, 0.9, 1.0),
	&"whistle": Color(0.9, 0.85, 0.6),
	&"key": Color(1.0, 0.85, 0.4),
	&"gem_jade": Color(0.3, 0.95, 0.5),
	&"gem_amber": Color(1.0, 0.7, 0.25),
	&"gem_violet": Color(0.75, 0.45, 1.0),
}

## 展出的道具
@export var item: StringName = &"lamp":
	set(value):
		item = value
		_update_visual()

## 悬浮上下浮动幅度（px）
@export var bob_amplitude: float = 3.0
## 浮动速度
@export var bob_speed: float = 2.0

var _t: float = 0.0
var _icon_base_y: float

@onready var _icon: Sprite2D = $Item
@onready var _glow: PointLight2D = get_node_or_null("Glow") as PointLight2D


func _ready() -> void:
	_icon_base_y = _icon.position.y
	_update_visual()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	_icon.position.y = _icon_base_y + sin(_t * TAU / bob_speed) * bob_amplitude


func _update_visual() -> void:
	if not is_node_ready():
		return
	var icon: Texture2D = ICONS.get(item)
	if icon != null:
		_icon.texture = icon
	if _glow != null:
		_glow.color = GLOW_COLORS.get(item, Color(1, 0.9, 0.7))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		Sfx.play(&"pickup")
		GameState.acquire_item(item)
		queue_free()
