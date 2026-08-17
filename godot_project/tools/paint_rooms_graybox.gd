extends SceneTree
## 生成 12 房间灰盒骨架（M8）：地板/围墙/出入口/门洞/梯子/能力门结构。
## 连接关系按策划案 §三房间一览与详设（progress.md §3 亦有摘录）：
##   1→2→3→4→5→6→7→8→9→11；7⇄10（梯子）；5→4（水体秘密通道回程）；
##   11→狭长通道→3（回环）；3 钥匙门→12（终局）。
## 目的：可流通的地图骨架 + 机制测试场。策划在灰盒上装修，不推翻出入口结构。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless --script tools/paint_rooms_graybox.gd

const TEMPLATE := "res://scenes/rooms/room_base.tscn"
const SRC := 1 # TileSet source：泥土（带碰撞+遮光）
const EDGE_TOP := Vector2i(0, 0)
const FILL := Vector2i(0, 2)
const FLOOR_ROW := 60 # 地面顶行（67 行高房间）
const TILE := 16.0

var _terrain: TileMapLayer
var _room: Node2D
var _room_w: int


func _initialize() -> void:
	for spec in _room_specs():
		_build_room(spec)
	print("all rooms painted")
	quit(0)


# ---- 房间规格表 ----
# entrances: {id: Vector2i 格}；exits: {pos 格(px 中心另算), target_room, target_entrance, side}
# side: right/left = 侧墙门洞（3 格高）；top = 天花板洞；bottom = 地板洞（坠落）
# walls_gap / ceiling_gap / floor_gap 由 exits 自动推出；extra_* 为附加结构
func _room_specs() -> Array[Dictionary]:
	var specs: Array[Dictionary] = []

	specs.append({
		"id": &"room_01", "label": "Room01",
		"entrances": {&"default": Vector2i(4, 59)},
		"exits": [{"pos": Vector2i(119, 58), "target_room": &"room_02", "target_entrance": &"default", "side": "right"}],
	})
	specs.append({
		"id": &"room_02", "label": "Room02",
		"entrances": {&"default": Vector2i(4, 59)},
		"exits": [{"pos": Vector2i(119, 58), "target_room": &"room_03", "target_entrance": &"default", "side": "right"}],
	})
	specs.append({
		"id": &"room_03", "label": "Room03",
		"entrances": {&"default": Vector2i(4, 59), &"corridor": Vector2i(6, 7)},
		"exits": [
			# 下方出口（策划案：水体下方左侧）→ room_04 顶部落入
			{"pos": Vector2i(9, 62), "target_room": &"room_04", "target_entrance": &"default", "side": "bottom"},
			# 左上狭长通道（5 格高墙挡首次通过，需二段跳）→ room_11 右端
			{"pos": Vector2i(2, 7), "target_room": &"room_11", "target_entrance": &"corridor", "side": "left_high"},
			# 右上钥匙门 → room_12（终局入口）
			{"pos": Vector2i(117, 18), "target_room": &"room_12", "target_entrance": &"default", "side": "right_high"},
		],
		"platforms": [
			# 左上高台（行 8，通道入口落脚处）
			Rect2i(2, 8, 7, 1),
			# 右上钥匙门高台（行 20）
			Rect2i(100, 20, 19, 1),
		],
		# 5 格高墙（行 55..59）：能力门——无靴不可越，策划案 §三(三)"首次无法到达"
		"blocks": [Rect2i(12, 55, 1, 5)],
		"ladders": [Rect2i(6, 9, 1, 50), Rect2i(102, 21, 1, 38)],
		"key_door": Vector2i(117, 18), # 挡在右上出口前
	})
	specs.append({
		"id": &"room_04", "label": "Room04",
		"entrances": {&"default": Vector2i(60, 4), &"secret": Vector2i(31, 55)},
		"exits": [
			# 左侧出口 → room_05 右侧平台（策划案 §三(四)"左侧有一扇门通往第5房间"）
			{"pos": Vector2i(0, 58), "target_room": &"room_05", "target_entrance": &"default", "side": "left"},
		],
		# 顶部落井（承接 room_03 下方出口）
		"shafts": [Rect2i(59, 0, 3, 60)],
		"ceiling_gaps": [Vector2i(60, 0)],
		# 秘密水潭（room_05 水体通道回程冒头处）
		"water": [Rect2i(28, 61, 7, 6)],
		# 跨房间机关演示：底部狮子头按钮开 room_05 的石门（策划案 §三(五)）
		"lion_buttons": [{"pos": Vector2i(60, 59), "target_id": &"r05_door2"}],
	})
	specs.append({
		"id": &"room_05", "label": "Room05",
		"entrances": {&"default": Vector2i(114, 59)},
		"exits": [
			{"pos": Vector2i(0, 58), "target_room": &"room_06", "target_entrance": &"default", "side": "left"},
			# 水体秘密通道（回程）→ room_04 水潭（策划案 §三(五)）
			{"pos": Vector2i(91, 62), "target_room": &"room_04", "target_entrance": &"secret", "side": "bottom"},
		],
		# 左门洞被石门挡住：listen r05_door2（按钮在 room_04，跨房间联动）
		"stone_doors": [{"pos": Vector2i(1, 58), "listen_id": &"r05_door2"}],
		"water": [Rect2i(88, 61, 7, 6)],
	})
	specs.append({
		"id": &"room_06", "label": "Room06",
		"entrances": {&"default": Vector2i(114, 59)},
		"exits": [{"pos": Vector2i(0, 58), "target_room": &"room_07", "target_entrance": &"default", "side": "left"}],
	})
	specs.append({
		"id": &"room_07", "label": "Room07",
		"entrances": {&"default": Vector2i(114, 59), &"top": Vector2i(60, 13)},
		"exits": [
			{"pos": Vector2i(0, 58), "target_room": &"room_08", "target_entrance": &"default", "side": "left"},
			# 顶部梯子 → room_10（策划案 §三(七)）
			{"pos": Vector2i(60, 1), "target_room": &"room_10", "target_entrance": &"default", "side": "top"},
		],
		"platforms": [Rect2i(55, 14, 11, 1)],
		"ladders": [Rect2i(60, 15, 1, 44)],
		"ceiling_gaps": [Vector2i(60, 0)],
	})
	specs.append({
		"id": &"room_08", "label": "Room08",
		"entrances": {&"default": Vector2i(6, 59), &"top": Vector2i(110, 7)},
		"exits": [
			# 右上高台 → room_09（策划案 §三(八)"右上梯子通往第9房间"）
			{"pos": Vector2i(119, 7), "target_room": &"room_09", "target_entrance": &"default", "side": "right_high"},
		],
		"platforms": [Rect2i(106, 8, 13, 1)],
		"ladders": [Rect2i(110, 9, 1, 50)],
		# 地刺底床（策划案 §三(八)：坠落即失败）
		"spikes": [Rect2i(30, 59, 60, 1)],
	})
	specs.append({
		"id": &"room_09", "label": "Room09",
		"entrances": {&"default": Vector2i(6, 7), &"from_11": Vector2i(112, 59)},
		"exits": [
			# 右侧出口 → room_11（策划案 §三(九)）
			{"pos": Vector2i(119, 58), "target_room": &"room_11", "target_entrance": &"default", "side": "right"},
			# 左下返回 room_08 右上高台
			{"pos": Vector2i(2, 7), "target_room": &"room_08", "target_entrance": &"top", "side": "left_high"},
		],
		"platforms": [Rect2i(2, 8, 8, 1)],
		"ladders": [Rect2i(6, 9, 1, 50)],
		# 老鼠窄缝：x=40 墙体只留底行 1 格高通道（能力门：玩家不可过）
		"blocks": [Rect2i(40, 55, 1, 4)],
		"pickups": [{"pos": Vector2i(44, 59), "item": &"gem_amber"}], # 窄缝后奖励位（灰盒演示）
	})
	specs.append({
		"id": &"room_10", "label": "Room10",
		"entrances": {&"default": Vector2i(60, 6)},
		"exits": [
			# 原路返回 room_07 顶部平台（策划案 §三(十)：返回第7房间）
			{"pos": Vector2i(60, 1), "target_room": &"room_07", "target_entrance": &"top", "side": "top"},
		],
		"platforms": [Rect2i(55, 7, 11, 1)],
		"ladders": [Rect2i(60, 8, 1, 51)],
		"ceiling_gaps": [Vector2i(60, 0)],
	})
	specs.append({
		"id": &"room_11", "label": "Room11",
		"entrances": {&"default": Vector2i(4, 59), &"corridor": Vector2i(112, 59)},
		"exits": [
			# 右侧狭长通道 → room_03 左上（策划案 §三(十一)"从深处回归"闭环）
			{"pos": Vector2i(119, 58), "target_room": &"room_03", "target_entrance": &"corridor", "side": "right"},
		],
	})
	specs.append({
		"id": &"room_12", "label": "Room12", "width": 360, # 策划案：5760×1080（360×67 格）
		"entrances": {&"default": Vector2i(4, 59)},
		"exits": [], # 结局出口在 M9 实现
		# 三层结构空壳（策划案 §三(十二)：潜行层/追赶层/宝石层），M9 填充内容
		"platforms": [Rect2i(30, 45, 300, 1), Rect2i(60, 30, 280, 1), Rect2i(90, 15, 260, 1)],
		"ladders": [Rect2i(100, 46, 1, 13), Rect2i(200, 31, 1, 14), Rect2i(300, 16, 1, 14)],
	})

	return specs


# ---- 生成 ----

func _build_room(spec: Dictionary) -> void:
	# 从零构建（镜像 room_base.tscn 结构）——继承场景 pack 时子节点修改有丢失风险，不用模板实例化
	_room_w = spec.get("width", 120)
	_room = Node2D.new()
	_room.name = spec["label"]
	_room.set_script(load("res://scripts/rooms/room_base.gd"))
	root.add_child(_room)
	_room.set("room_id", spec["id"])

	var dark := CanvasModulate.new()
	dark.name = "CanvasModulate"
	dark.color = Color(0.45, 0.45, 0.45, 1)
	_room.add_child(dark)
	dark.owner = _room

	var bg := TextureRect.new()
	bg.name = "Background"
	bg.z_index = -10
	bg.offset_right = _room_w * TILE
	bg.offset_bottom = 1080.0
	bg.texture = load("res://assets/placeholder/bg_cave.png")
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	_room.add_child(bg)
	bg.owner = _room

	var tileset := load("res://assets/tiles/tileset_cave.tres") as TileSet
	_terrain = TileMapLayer.new()
	_terrain.name = "TileMapTerrain"
	_terrain.tile_set = tileset
	_room.add_child(_terrain)
	_terrain.owner = _room
	for layer_name in ["TileMapDecor", "TileMapMechanismMarkers"]:
		var layer := TileMapLayer.new()
		layer.name = layer_name
		layer.tile_set = tileset
		_room.add_child(layer)
		layer.owner = _room
	for group_name in ["Mechanisms", "Characters", "Lights"]:
		var group := Node2D.new()
		group.name = group_name
		_room.add_child(group)
		group.owner = _room

	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.add_to_group(&"spawn_point")
	_room.add_child(spawn)
	spawn.owner = _room

	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.position = Vector2(240, 135)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = _room_w * int(TILE)
	cam.limit_bottom = 1080
	cam.enabled = true
	_room.add_child(cam)
	cam.owner = _room
	var host := Node.new()
	host.name = "PhantomCameraHost"
	host.set_script(load("res://addons/phantom_camera/scripts/phantom_camera_host/phantom_camera_host.gd"))
	cam.add_child(host)
	host.owner = _room

	_paint_shell(spec)
	_paint_structures(spec)
	_place_markers(spec)
	_place_exits(spec)
	_place_mechanisms(spec)

	# 出生点对齐默认入口（兼容旧逻辑与独立运行）
	var def: Vector2i = (spec["entrances"] as Dictionary)[&"default"]
	spawn.position = _tile_center(def)

	var packed := PackedScene.new()
	var path := "res://scenes/rooms/%s.tscn" % spec["id"]
	if packed.pack(_room) != OK or ResourceSaver.save(packed, path) != OK:
		printerr("save failed: ", path)
		quit(1)
		return
	print("  ", path)
	_room.queue_free()


func _tile_center(t: Vector2i) -> Vector2:
	return Vector2(t) * TILE + Vector2(TILE / 2.0, TILE / 2.0)


func _fill(rect: Rect2i, atlas: Vector2i = FILL) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			_terrain.set_cell(Vector2i(x, y), SRC, atlas)


func _paint_shell(spec: Dictionary) -> void:
	var w := _room_w
	# 地面（含顶行草皮）
	for x in range(0, w):
		_terrain.set_cell(Vector2i(x, FLOOR_ROW), SRC, EDGE_TOP)
	_fill(Rect2i(0, FLOOR_ROW + 1, w, 67 - FLOOR_ROW - 1))
	# 左右围墙 + 天花板
	_fill(Rect2i(0, 0, 1, FLOOR_ROW))
	_fill(Rect2i(w - 1, 0, 1, FLOOR_ROW))
	_fill(Rect2i(0, 0, w, 1))
	# 出口挖洞
	for exit in spec["exits"]:
		var p: Vector2i = exit["pos"]
		match exit["side"]:
			"right":
				_fill_air(Rect2i(w - 1, p.y - 1, 1, 3))
			"left":
				_fill_air(Rect2i(0, p.y - 1, 1, 3))
			"right_high":
				_fill_air(Rect2i(w - 1, p.y - 1, 1, 3))
			"left_high":
				_fill_air(Rect2i(0, p.y - 1, 1, 3))
			"top":
				_fill_air(Rect2i(p.x, 0, 1, 1))
			"bottom":
				_fill_air(Rect2i(p.x - 1, FLOOR_ROW, 3, 67 - FLOOR_ROW))
	# 天花板附加洞
	for gap in spec.get("ceiling_gaps", []):
		_terrain.erase_cell(gap)
	# 地板附加洞（刺坑等）
	for rect in spec.get("floor_gaps_extra", []):
		_fill_air(rect)


func _fill_air(rect: Rect2i) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			_terrain.erase_cell(Vector2i(x, y))


func _paint_structures(spec: Dictionary) -> void:
	for rect in spec.get("platforms", []):
		_fill(rect, EDGE_TOP)
	for rect in spec.get("blocks", []):
		_fill(rect, FILL)
	for rect in spec.get("shafts", []):
		# 落井：两侧井壁（中间已在天花板/常规结构留空）
		_fill(Rect2i(rect.position.x - 1, rect.position.y, 1, rect.size.y))
		_fill(Rect2i(rect.position.x + rect.size.x, rect.position.y, 1, rect.size.y))


func _place_markers(spec: Dictionary) -> void:
	for entrance_id in spec["entrances"]:
		var marker := Marker2D.new()
		marker.name = "Entrance_" + String(entrance_id)
		marker.position = _tile_center((spec["entrances"] as Dictionary)[entrance_id])
		_room.add_child(marker)
		marker.owner = _room


func _place_exits(spec: Dictionary) -> void:
	for exit in spec["exits"]:
		var node := (load("res://scenes/interactables/room_exit.tscn") as PackedScene).instantiate() as Area2D
		node.name = "Exit_to_%s" % exit["target_room"]
		node.position = _tile_center(exit["pos"])
		node.set("target_room", exit["target_room"])
		node.set("target_entrance", exit["target_entrance"])
		_room.add_child(node)
		node.owner = _room


func _place_mechanisms(spec: Dictionary) -> void:
	var mech := _room.get_node("Mechanisms")
	for rect in spec.get("ladders", []):
		# 梯子积木高 6 格（96px，原点在底端），长梯分段堆叠
		var rows: int = rect.size.y
		var placed := 0
		while placed < rows:
			var seg: int = mini(6, rows - placed)
			var ladder := (load("res://scenes/interactables/ladder.tscn") as PackedScene).instantiate() as Node2D
			var bottom_row: int = rect.position.y + placed + seg
			ladder.position = Vector2(rect.position.x * TILE, bottom_row * TILE)
			if seg < 6:
				# 不满 6 格的尾段：压缩碰撞与视觉高度
				var shape_node := ladder.get_node("CollisionShape2D") as CollisionShape2D
				var rect_shape := (shape_node.shape as RectangleShape2D).duplicate() as RectangleShape2D
				rect_shape.size = Vector2(16, seg * TILE)
				shape_node.shape = rect_shape
				shape_node.position = Vector2(8, -seg * TILE / 2.0)
				var visual := ladder.get_node("ColorRect") as ColorRect
				visual.offset_top = -seg * TILE
				visual.offset_bottom = 0.0
			mech.add_child(ladder)
			ladder.owner = _room
			placed += seg
	for rect in spec.get("water", []):
		var water := (load("res://scenes/interactables/water.tscn") as PackedScene).instantiate() as Node2D
		water.position = Vector2(rect.position) * TILE
		# 默认 96×48，按规格拉伸碰撞与视觉
		var shape_node := water.get_node("CollisionShape2D") as CollisionShape2D
		var rect_shape := (shape_node.shape as RectangleShape2D).duplicate() as RectangleShape2D
		rect_shape.size = Vector2(rect.size.x * TILE, rect.size.y * TILE)
		shape_node.shape = rect_shape
		shape_node.position = rect_shape.size / 2.0
		var visual := water.get_node("ColorRect") as ColorRect
		visual.offset_right = rect.size.x * TILE
		visual.offset_bottom = rect.size.y * TILE
		mech.add_child(water)
		water.owner = _room
	for rect in spec.get("spikes", []):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var spike := (load("res://scenes/interactables/spikes.tscn") as PackedScene).instantiate() as Node2D
			# 刺底贴地面顶（判定 14×8，原点在图中心）
			spike.position = _tile_center(Vector2i(x, rect.position.y)) + Vector2(0, 4)
			mech.add_child(spike)
			spike.owner = _room
	for btn in spec.get("lion_buttons", []):
		var button := (load("res://scenes/interactables/lion_button.tscn") as PackedScene).instantiate() as Node2D
		button.position = _tile_center(btn["pos"])
		button.set("target_id", btn["target_id"])
		mech.add_child(button)
		button.owner = _room
	for door in spec.get("stone_doors", []):
		var d := (load("res://scenes/interactables/stone_door.tscn") as PackedScene).instantiate() as Node2D
		d.position = _tile_center(door["pos"])
		d.set("listen_id", door["listen_id"])
		mech.add_child(d)
		d.owner = _room
	if spec.has("key_door"):
		var kd := (load("res://scenes/interactables/key_door.tscn") as PackedScene).instantiate() as Node2D
		kd.position = _tile_center(spec["key_door"])
		mech.add_child(kd)
		kd.owner = _room
	for pk in spec.get("pickups", []):
		var item := (load("res://scenes/interactables/pickup.tscn") as PackedScene).instantiate() as Node2D
		item.position = _tile_center(pk["pos"])
		item.set("item", pk["item"])
		mech.add_child(item)
		item.owner = _room
