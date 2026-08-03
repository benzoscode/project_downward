extends SceneTree
## 生成 M1 演示房间：room_base 模板 + 地形 + 玩家，保存为 scenes/rooms/demo_room.tscn。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless --script tools/paint_demo_room.gd
## 说明：tile_map_data 二进制格式不宜手写，故用引擎自身序列化产出 .tscn。
## 该房间仅供开发验证与审阅手感，正式房间由策划用编辑器搭建。

const FLOOR_TOP := 63 # 地面顶行（格）

var _atlas_solid := Vector2i(0, 0)
var _atlas_platform := Vector2i(2, 0)
var _atlas_moss := Vector2i(0, 1)
var _atlas_crack := Vector2i(2, 1)


func _initialize() -> void:
	var base := load("res://scenes/templates/room_base.tscn") as PackedScene
	var room := base.instantiate() as Node2D
	room.scene_file_path = "" # 打包为新场景而非模板实例引用
	root.add_child(room)

	var terrain := room.get_node("TileMapTerrain") as TileMapLayer
	# 地面：底部 4 行整宽实心
	for x in range(0, 120):
		for y in range(FLOOR_TOP, 67):
			terrain.set_cell(Vector2i(x, y), 0, _atlas_solid)
	# 左右墙壁
	for y in range(50, 67):
		terrain.set_cell(Vector2i(0, y), 0, _atlas_solid)
		terrain.set_cell(Vector2i(119, y), 0, _atlas_solid)
	# 错落平台：验证跳跃与惯性
	for x in range(20, 29):
		terrain.set_cell(Vector2i(x, 58), 0, _atlas_platform)
	for x in range(36, 44):
		terrain.set_cell(Vector2i(x, 54), 0, _atlas_platform)
	for x in range(52, 62):
		terrain.set_cell(Vector2i(x, 50), 0, _atlas_platform)

	# 装饰：苔藓与裂纹点缀地面
	var decor := room.get_node("TileMapDecor") as TileMapLayer
	for x in range(0, 120):
		if x % 7 == 3:
			decor.set_cell(Vector2i(x, FLOOR_TOP - 1), 0, _atlas_moss)
		elif x % 11 == 5:
			decor.set_cell(Vector2i(x, FLOOR_TOP - 1), 0, _atlas_crack)

	# 出生点与玩家
	var spawn := room.get_node("SpawnPoint") as Marker2D
	spawn.position = Vector2(80, 15 * 16)
	var player_scene := load("res://scenes/characters/player.tscn") as PackedScene
	var player := player_scene.instantiate() as CharacterBody2D
	player.position = spawn.position
	room.get_node("Characters").add_child(player)
	player.owner = room

	var packed := PackedScene.new()
	var pack_err := packed.pack(room)
	if pack_err != OK:
		printerr("pack failed: ", error_string(pack_err))
		quit(1)
		return
	var save_err := ResourceSaver.save(packed, "res://scenes/rooms/demo_room.tscn")
	if save_err != OK:
		printerr("save failed: ", error_string(save_err))
		quit(1)
		return
	print("demo room saved: res://scenes/rooms/demo_room.tscn")
	quit(0)
