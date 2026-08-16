extends SceneTree
## 生成手感对比试验场：单屏 480×270、固定镜头、三条 identical 跑道，
## 三名玩家变体吃同一份输入，并排对比跳跃时间曲线（高度均保持策划案 3 格）。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless --script tools/paint_movement_lab.gd

const TILE := 16
const SCREEN_W := 30 # 格
const SCREEN_H := 17
const LANE_FLOORS: Array[int] = [4, 9, 14] # 各跑道地面顶行

var _atlas_solid := Vector2i(0, 0)
var _atlas_platform := Vector2i(2, 0)

# 变体：仅跳跃时间曲线不同（jump_time_to_apex / fall_gravity_multiplier）
var _variants: Array[Dictionary] = [
	{"tag": "A", "apex": 0.35, "fall": 1.4, "tint": Color(1, 1, 1), "desc": "A: 0.35s x1.4 (current)"},
	{"tag": "B", "apex": 0.28, "fall": 1.8, "tint": Color(0.4, 0.9, 1), "desc": "B: 0.28s x1.8"},
	{"tag": "C", "apex": 0.24, "fall": 2.5, "tint": Color(1, 0.7, 0.3), "desc": "C: 0.24s x2.5"},
]


func _initialize() -> void:
	var lab := Node2D.new()
	lab.name = "MovementLab"
	root.add_child(lab)

	# 深蓝灰背景：比纯黑默认清屏色更易读（仅开发工具用，不代表游戏氛围）
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.10, 0.12, 0.18, 1)
	bg.size = Vector2(SCREEN_W * TILE, SCREEN_H * TILE)
	lab.add_child(bg)
	bg.owner = lab

	var terrain := TileMapLayer.new()
	terrain.name = "TileMapTerrain"
	terrain.tile_set = load("res://assets/placeholder/tileset_cave.tres") as TileSet
	lab.add_child(terrain)
	terrain.owner = lab

	# 全屏左右墙壁
	for y in range(0, SCREEN_H):
		terrain.set_cell(Vector2i(0, y), 0, _atlas_solid)
		terrain.set_cell(Vector2i(SCREEN_W - 1, y), 0, _atlas_solid)

	var player_scene := load("res://scenes/characters/player.tscn") as PackedScene
	for i in _variants.size():
		var f: int = LANE_FLOORS[i]
		# 跑道地面：2 行厚（底行 lane 补到屏幕底）
		var strip_bottom: int = f + 1 if i < 2 else SCREEN_H - 1
		for x in range(1, SCREEN_W - 1):
			for y in range(f, strip_bottom + 1):
				terrain.set_cell(Vector2i(x, y), 0, _atlas_solid)
		# 2 格台阶 + 3 格立柱：检验跳跃高度与弧线
		for x in range(12, 14):
			for y in range(f - 2, f):
				terrain.set_cell(Vector2i(x, y), 0, _atlas_platform)
		for x in range(20, 23):
			for y in range(f - 3, f):
				terrain.set_cell(Vector2i(x, y), 0, _atlas_platform)

		var v: Dictionary = _variants[i]
		var player := player_scene.instantiate() as CharacterBody2D
		player.name = "Player%s" % v["tag"]
		player.position = Vector2(3 * TILE, f * TILE - 12)
		player.set("jump_time_to_apex", v["apex"])
		player.set("fall_gravity_multiplier", v["fall"])
		# 固定镜头试验场无 PhantomCameraHost，压低优先级确保不抢镜
		player.get_node("PhantomCamera2D").set("priority", 0)
		lab.add_child(player)
		player.owner = lab
		(player.get_node("AnimatedSprite2D") as CanvasItem).modulate = v["tint"]

		var label := Label.new()
		label.name = "Label%s" % v["tag"]
		label.text = v["desc"]
		label.position = Vector2(1.5 * TILE, (f - 4) * TILE)
		label.add_theme_color_override("font_color", v["tint"])
		lab.add_child(label)
		label.owner = lab

	# 固定镜头：居中整屏，无跟随无阻尼
	var camera := Camera2D.new()
	camera.name = "FixedCamera"
	camera.position = Vector2(SCREEN_W * TILE / 2.0, SCREEN_H * TILE / 2.0)
	camera.enabled = true
	lab.add_child(camera)
	camera.owner = lab

	var packed := PackedScene.new()
	if packed.pack(lab) != OK:
		printerr("pack failed")
		quit(1)
		return
	if ResourceSaver.save(packed, "res://scenes/test/movement_lab.tscn") != OK:
		printerr("save failed")
		quit(1)
		return
	print("movement lab saved: res://scenes/test/movement_lab.tscn")
	quit(0)
