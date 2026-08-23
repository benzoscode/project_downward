extends CanvasLayer
## 极简 HUD（Autoload: HUD）：道具获取弹窗 + 左上角持有图标栏。
## 占位 UI，M10 视听打磨时整体重做。

const ICONS: Dictionary = {
	&"lamp": preload("res://assets/props/item_lamp.png"),
	&"boots": preload("res://assets/props/item_boots.png"),
	&"whistle": preload("res://assets/props/item_whistle.png"),
	&"key": preload("res://assets/props/item_key.png"),
	&"gem_jade": preload("res://assets/props/item_gem_jade.png"),
	&"gem_amber": preload("res://assets/props/item_gem_amber.png"),
	&"gem_violet": preload("res://assets/props/item_gem_violet.png"),
}

var _inventory: HBoxContainer
var _toast_icon: TextureRect
var _toast_label: Label
var _toast: HBoxContainer
var _toast_tween: Tween = null


func _ready() -> void:
	layer = 10
	_inventory = HBoxContainer.new()
	_inventory.position = Vector2(4, 4)
	add_child(_inventory)

	# 底部居中弹窗：图标 + 道具名
	_toast = HBoxContainer.new()
	_toast.position = Vector2(200, 240)
	_toast.modulate.a = 0.0
	_toast_icon = TextureRect.new()
	_toast_icon.stretch_mode = TextureRect.STRETCH_SCALE
	_toast_icon.custom_minimum_size = Vector2(32, 32)
	_toast.add_child(_toast_icon)
	_toast_label = Label.new()
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY # 任意字符换行（中文无空格）
	_toast_label.custom_minimum_size = Vector2(240, 0) # 限宽自动折行
	_toast.add_child(_toast_label)
	add_child(_toast)

	GameState.item_acquired.connect(_on_item_acquired)
	_refresh_inventory()


func _on_item_acquired(item: StringName) -> void:
	_refresh_inventory()
	_toast.position = Vector2(200, 240)
	_toast_icon.texture = ICONS.get(item)
	_toast_label.text = " Got: " + String(item)
	_show_toast(2.0)


## 文字提示弹窗（告示牌等积木用，无图标）。多行支持：位置上移 + 自动换行
func show_message(text: String, duration: float = 3.5) -> void:
	_toast.position = Vector2(120, 200) # 抬高，给多行留足下方空间（视口高 270）
	_toast_icon.texture = null
	_toast_label.text = " " + text
	_show_toast(duration)


func _show_toast(hold: float) -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast.modulate.a = 1.0
	_toast_tween.tween_interval(hold)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


func _refresh_inventory() -> void:
	for child in _inventory.get_children():
		child.queue_free()
	for item: StringName in ICONS.keys():
		if not _has_item(item):
			continue
		var rect := TextureRect.new()
		rect.texture = ICONS[item]
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		_inventory.add_child(rect)


func _has_item(item: StringName) -> bool:
	match item:
		&"lamp":
			return GameState.has_lamp
		&"boots":
			return GameState.has_boots
		&"whistle":
			return GameState.has_whistle
		&"key":
			return GameState.has_key
		_:
			return GameState.gems.has(item)
