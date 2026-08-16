extends SceneTree
## 生成镜头试验场：90 格长跑道（约 3 屏宽）+ 跟随镜头，配合 scripts/test/camera_lab.gd。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless --script tools/paint_camera_lab.gd

const TILE := 16
const TRACK_W := 90 # 格
const SCREEN_H := 17
const FLOOR_TOP := 12 # 地面顶行

var _atlas_solid := Vector2i(0, 0)
var _atlas_platform := Vector2i(2, 0)


func _initialize() -> void:
	var lab := Node2D.new()
	lab.name = "CameraLab"
	lab.set_script(load("res://scripts/test/camera_lab.gd"))
	root.add_child(lab)

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.10, 0.12, 0.18, 1)
	bg.size = Vector2(TRACK_W * TILE, SCREEN_H * TILE)
	lab.add_child(bg)
	bg.owner = lab

	var terrain := TileMapLayer.new()
	terrain.name = "TileMapTerrain"
	terrain.tile_set = load("res://assets/tiles/tileset_cave.tres") as TileSet
	lab.add_child(terrain)
	terrain.owner = lab

	# 地面通铺 + 两端墙壁
	for x in range(0, TRACK_W):
		for y in range(FLOOR_TOP, SCREEN_H):
			terrain.set_cell(Vector2i(x, y), 0, _atlas_solid)
	for y in range(0, SCREEN_H):
		terrain.set_cell(Vector2i(0, y), 0, _atlas_solid)
		terrain.set_cell(Vector2i(TRACK_W - 1, y), 0, _atlas_solid)
	# 平台与立柱：迫使跳跃，检验垂直跟随
	for x in range(20, 27):
		terrain.set_cell(Vector2i(x, 9), 0, _atlas_platform)
	for x in range(40, 47):
		terrain.set_cell(Vector2i(x, 6), 0, _atlas_platform)
	for x in range(60, 63):
		for y in range(FLOOR_TOP - 3, FLOOR_TOP):
			terrain.set_cell(Vector2i(x, y), 0, _atlas_platform)
	for x in range(75, 77):
		for y in range(FLOOR_TOP - 2, FLOOR_TOP):
			terrain.set_cell(Vector2i(x, y), 0, _atlas_platform)

	var characters := Node2D.new()
	characters.name = "Characters"
	lab.add_child(characters)
	characters.owner = lab

	var player := (load("res://scenes/characters/player.tscn") as PackedScene).instantiate() as CharacterBody2D
	player.name = "Player"
	# 出生点越过首屏中心（240px），避免开局镜头压在左边界外露出黑边
	player.position = Vector2(20 * TILE, FLOOR_TOP * TILE - 12)
	characters.add_child(player)
	player.owner = lab

	# 与 room_base 一致：Camera2D + PhantomCameraHost，由玩家的 pcam 接管
	var camera := Camera2D.new()
	camera.name = "RoomCamera"
	camera.position = player.position
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = TRACK_W * TILE
	camera.limit_bottom = SCREEN_H * TILE
	camera.enabled = true
	lab.add_child(camera)
	camera.owner = lab

	var host := Node.new()
	host.name = "PhantomCameraHost"
	host.set_script(load("res://addons/phantom_camera/scripts/phantom_camera_host/phantom_camera_host.gd"))
	camera.add_child(host)
	host.owner = lab

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	lab.add_child(hud)
	hud.owner = lab

	var label := Label.new()
	label.name = "Label"
	label.position = Vector2(8, 8)
	label.add_theme_font_size_override("font_size", 8)
	hud.add_child(label)
	label.owner = lab

	var packed := PackedScene.new()
	if packed.pack(lab) != OK:
		printerr("pack failed")
		quit(1)
		return
	if ResourceSaver.save(packed, "res://scenes/test/camera_lab.tscn") != OK:
		printerr("save failed")
		quit(1)
		return
	print("camera lab saved: res://scenes/test/camera_lab.tscn")
	quit(0)
