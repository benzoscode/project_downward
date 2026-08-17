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
	_assert(ts.get_source_count() == 12, "source 总数为 12（占位 + 4 分区 + 第三批 7 区），实际 %d" % ts.get_source_count())

	var dirt := ts.get_source(1) as TileSetAtlasSource
	var dirt_td := dirt.get_tile_data(Vector2i(0, 0), 0)
	_assert(dirt != null and dirt_td.get_collision_polygons_count(0) == 1
		and dirt_td.get_collision_polygon_points(0, 0).size() == 4
		and dirt_td.get_collision_polygon_points(0, 0)[2] == Vector2(8, 8),
		"分区1 泥土图块带有效碰撞（4 点全格）")
	var stone := ts.get_source(2) as TileSetAtlasSource
	_assert(stone != null and stone.get_tile_data(Vector2i(6, 0), 0).get_collision_polygons_count(0) == 1,
		"分区2 石质图块带碰撞")
	var decor := ts.get_source(3) as TileSetAtlasSource
	_assert(decor != null and decor.get_tile_data(Vector2i(0, 0), 0).get_collision_polygons_count(0) == 0,
		"分区3 装饰无碰撞")
	var big := ts.get_source(4) as TileSetAtlasSource
	_assert(big != null and big.texture_region_size == Vector2i(32, 32),
		"分区4 单元格 32×32")
	# 第三批：石砖/草丛/水面/水体动画
	var brick := ts.get_source(5) as TileSetAtlasSource
	_assert(brick != null and brick.get_tile_data(Vector2i(0, 0), 0).get_collision_polygons_count(0) == 1
		and brick.get_tile_data(Vector2i(7, 0), 0).get_collision_polygons_count(0) == 1,
		"分区5 石砖 8 格带碰撞+遮光")
	var grass := ts.get_source(6) as TileSetAtlasSource
	_assert(grass != null and grass.has_tile(Vector2i(0, 0)) and grass.has_tile(Vector2i(6, 0))
		and grass.get_tile_data(Vector2i(6, 0), 0).get_collision_polygons_count(0) == 0,
		"分区6 草丛 7 格无碰撞")
	var surface := ts.get_source(7) as TileSetAtlasSource
	_assert(surface != null and surface.get_tile_animation_frames_count(Vector2i(0, 0)) == 1,
		"分区7 水面静态瓦片")
	var calm := ts.get_source(8) as TileSetAtlasSource
	_assert(calm != null and calm.get_tile_animation_frames_count(Vector2i(0, 0)) == 9
		and is_equal_approx(calm.get_tile_animation_speed(Vector2i(0, 0)), 6.0),
		"分区8 平静水体 9 帧动画 @6fps")
	var calm_long := ts.get_source(9) as TileSetAtlasSource
	var wave1 := ts.get_source(10) as TileSetAtlasSource
	var wave2 := ts.get_source(11) as TileSetAtlasSource
	_assert(calm_long != null and calm_long.get_tile_animation_frames_count(Vector2i(0, 0)) == 18
		and wave1 != null and wave1.get_tile_animation_frames_count(Vector2i(0, 0)) == 16
		and wave2 != null and wave2.get_tile_animation_frames_count(Vector2i(0, 0)) == 16,
		"分区9-11 水体动画 18/16/16 帧")

	print("VERIFY RESULT: ", "FAILED" if _failed else "ALL PASSED")
	quit(1 if _failed else 0)
