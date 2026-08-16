extends SceneTree
## TileSet 分区校验：断言各分区图集挂载、格子数量与碰撞配置。
## 用法：& <godot_console.exe> --headless --script tools/verify/verify_tileset.gd

var _failed := false


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("[PASS] ", msg)
	else:
		_failed = true
		printerr("[FAIL] ", msg)


func _initialize() -> void:
	var ts := load("res://assets/tiles/tileset_cave.tres") as TileSet
	_assert(ts != null, "TileSet 可加载")
	if ts == null:
		quit(1)
		return
	_assert(ts.get_source_count() == 5, "source 总数为 5（占位 + 4 分区），实际 %d" % ts.get_source_count())

	var dirt := ts.get_source(1) as TileSetAtlasSource
	_assert(dirt != null and dirt.get_tile_data(Vector2i(0, 0), 0).get_collision_polygons_count(0) == 1,
		"分区1 泥土图块带碰撞")
	var stone := ts.get_source(2) as TileSetAtlasSource
	_assert(stone != null and stone.get_tile_data(Vector2i(6, 0), 0).get_collision_polygons_count(0) == 1,
		"分区2 石质图块带碰撞")
	var decor := ts.get_source(3) as TileSetAtlasSource
	_assert(decor != null and decor.get_tile_data(Vector2i(0, 0), 0).get_collision_polygons_count(0) == 0,
		"分区3 装饰无碰撞")
	var big := ts.get_source(4) as TileSetAtlasSource
	_assert(big != null and big.texture_region_size == Vector2i(32, 32),
		"分区4 单元格 32×32")

	print("VERIFY RESULT: ", "FAILED" if _failed else "ALL PASSED")
	quit(1 if _failed else 0)
