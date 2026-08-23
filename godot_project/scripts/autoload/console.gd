extends CanvasLayer
## 调试控制台（Autoload: Console，2026-08-23）：按 ` 打开，输入命令回车执行。
## 打开时暂停游戏树并锁定玩家输入；再按 ` 关闭。用于快速获取道具/传送/测试。
## 命令见 help。

## 道具别名 → GameState.acquire_item 参数
const ITEM_ALIAS := {
	&"lamp": &"lamp", &"灯": &"lamp",
	&"boots": &"boots", &"靴": &"boots", &"羽翎靴": &"boots",
	&"whistle": &"whistle", &"哨": &"whistle", &"召唤哨": &"whistle",
	&"key": &"key", &"钥匙": &"key",
	&"jade": &"gem_jade", &"翡翠": &"gem_jade",
	&"amber": &"gem_amber", &"琥珀": &"gem_amber",
	&"violet": &"gem_violet", &"紫金": &"gem_violet",
}
const ALL_ITEMS: Array[StringName] = [
	&"lamp", &"boots", &"whistle", &"key", &"gem_jade", &"gem_amber", &"gem_violet",
]
const ROOM_BASE := "res://scenes/rooms/room_"

var _open := false
var _history: PackedStringArray = []
var _history_idx := -1
var _line: LineEdit
var _output: Label
var _panel: PanelContainer


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS # 暂停树时仍可交互
	_build_ui()
	set_process_unhandled_input(true)


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.offset_bottom = 150.0
	_panel.visible = false
	add_child(_panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.1, 0.92)
	_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	_line = LineEdit.new()
	_line.placeholder_text = "输入命令（get_item lamp / goto 5 / help）"
	_line.add_theme_font_size_override("font_size", 10)
	_line.text_submitted.connect(_on_submit)
	_line.gui_input.connect(_on_line_gui_input)
	vbox.add_child(_line)

	# 屏上输出区：命令结果可见（不再只打 console）
	_output = Label.new()
	_output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_output.add_theme_font_size_override("font_size", 8)
	_output.custom_minimum_size = Vector2(0, 110)
	_output.text = "输入 help 查看命令\n"
	vbox.add_child(_output)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_QUOTELEFT:
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	_open = not _open
	_panel.visible = _open
	if _open:
		# 打开控制台：暂停游戏，避免打字触发移动/交互
		get_tree().paused = true
		_line.grab_focus()
		_line.clear()
	elif _open == false:
		get_tree().paused = false
		_line.release_focus()


func _on_submit(text: String) -> void:
	if _open:
		_line.clear()
	get_viewport().set_input_as_handled()
	_run(text)


## 命令分发。返回 false 表示未知命令。
func _run(text: String) -> void:
	text = text.strip_edges()
	if text.is_empty():
		return
	if _history.is_empty() or _history[_history.size() - 1] != text:
		_history.append(text)
	_history_idx = _history.size()
	var parts := text.split(" ", false, 1)
	var cmd := parts[0].to_lower()
	var arg: String = parts[1] if parts.size() > 1 else ""
	match cmd:
		&"close":
			_toggle()
		&"help":
			_print("命令说明")
			_print("get_item <道具>  道具(灯/靴/哨/钥匙/翡翠/琥珀/紫金)")
			_print("give_all 获得全部   clear_items 清空   items 查看持有")
			_print("goto <房间号|名> 传送   pos <x> <y> 瞬移")
			_print("lamp <on/off> 开关灯   respawn 重生   checkpoint 存点")
			_print("close 关闭控制台")
		&"get_item":
			_get_item(arg)
		&"give_all":
			for it in ALL_ITEMS:
				GameState.acquire_item(it)
			_print("已获得全部道具与宝石")
		&"clear_items":
			GameState.has_lamp = false
			GameState.has_boots = false
			GameState.has_whistle = false
			GameState.has_key = false
			GameState.gems.clear()
			_print("已清空道具与宝石")
		&"items":
			_print(_items_str())
		&"goto":
			_goto(arg)
		&"pos":
			_pos(arg)
		&"lamp":
			_lamp(arg)
		&"respawn":
			_respawn()
		&"checkpoint":
			_checkpoint()
		&"info":
			_print("房间=" + RoomManager.current_room_id + "  " + _items_str())
		_:
			_print("未知命令 " + cmd + "（输入 help 查看）")


func _get_item(arg: String) -> void:
	var key := arg.strip_edges().to_lower()
	if not ITEM_ALIAS.has(key):
		_print("未知道具 " + arg + "（lamp/boots/whistle/key/gem_* 或 灯/靴/哨/钥匙/翡翠/琥珀/紫金）")
		return
	GameState.acquire_item(ITEM_ALIAS[key])
	_print("获得 " + String(ITEM_ALIAS[key]))


func _goto(arg: String) -> void:
	var name := arg.strip_edges().to_lower()
	if name.is_valid_int():
		name = "room_%02d" % name.to_int()
	var path := ROOM_BASE + name + ".tscn"
	if not ResourceLoader.exists(path):
		_print("房间不存在 " + path)
		return
	# 关闭控制台后传送（避免暂停树时切场景）
	_open = false
	_panel.visible = false
	_line.release_focus()
	get_tree().paused = false
	RoomManager.goto_room(path, &"default")


func _pos(arg: String) -> void:
	var p := _player()
	if p == null:
		_print("无玩家")
		return
	var nums := arg.split(" ", false)
	if nums.size() < 2:
		_print("用法 pos <x> <y>")
		return
	p.global_position = Vector2(nums[0].to_float(), nums[1].to_float())
	p.velocity = Vector2.ZERO
	p.reset_physics_interpolation()


func _lamp(arg: String) -> void:
	var p := _player()
	if p == null:
		_print("无玩家")
		return
	var lamp: Node = p.get_node_or_null("Lamp")
	if lamp == null:
		_print("玩家无 Lamp 节点")
		return
	var on: bool = arg.strip_edges().to_lower() in ["on", "开", "1"]
	lamp.call("set_lamp_on", on)
	_print("灯 " + ("开" if on else "关"))


func _respawn() -> void:
	var p := _player()
	if p != null:
		p.call("die")


func _checkpoint() -> void:
	var p := _player()
	if p != null:
		GameState.set_checkpoint(RoomManager.current_room_id, p.global_position)
		_print("检查点已设为当前位置")


func _items_str() -> String:
	var parts: Array[String] = []
	if GameState.has_lamp:
		parts.append("灯")
	if GameState.has_boots:
		parts.append("靴")
	if GameState.has_whistle:
		parts.append("哨")
	if GameState.has_key:
		parts.append("钥匙")
	for g in GameState.gems:
		parts.append(String(g))
	return "道具: " + ("、".join(parts) if not parts.is_empty() else "无")


func _player() -> Node:
	return get_tree().get_first_node_in_group(&"player")


func _print(msg: String) -> void:
	print("[] ", msg)
	# 屏上显示（保留最近 8 行）
	var text := msg + "\n" + _output.text
	var lines := text.split("\n")
	while lines.size() > 9:
		lines.remove_at(lines.size() - 1)
	_output.text = "\n".join(lines)


## LineEdit 历史导航（上下键）+ 方向键默认行为
func _on_line_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_UP:
			if _history_idx > 0:
				_history_idx -= 1
				_line.text = _history[_history_idx]
				_line.caret_column = _line.text.length()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			if _history_idx < _history.size():
				_history_idx += 1
				_line.text = _history[_history_idx] if _history_idx < _history.size() else ""
				_line.caret_column = _line.text.length()
			get_viewport().set_input_as_handled()
