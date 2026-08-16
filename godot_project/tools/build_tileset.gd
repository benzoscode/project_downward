extends SceneTree
## 重建 TileSet：在既有占位图集（source 0）基础上追加正式素材的四个分区图集。
## 分区：1=泥土苔藓（带碰撞） 2=石质（带碰撞） 3=装饰 16px（无碰撞） 4=装饰 32px（无碰撞）
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless --script tools/build_tileset.gd
## 布局变更时同步修改本脚本与 docs/building_blocks.md 的分区表。

const TILESET_PATH := "res://assets/tiles/tileset_cave.tres"

# 每个分区：图集路径 / 单元格尺寸 / 占用格子 / 是否加碰撞
const ZONES: Array[Dictionary] = [
	{
		"id": 1,
		"texture": "res://assets/tiles/atlas_dirt.png",
		"region": Vector2i(16, 16),
		"cells": [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0),
			Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1),
			Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2),
			Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3),
		],
		"collision": true,
	},
	{
		"id": 2,
		"texture": "res://assets/tiles/atlas_stone.png",
		"region": Vector2i(16, 16),
		"cells": [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
			Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0),
		],
		"collision": true,
	},
	{
		"id": 3,
		"texture": "res://assets/decor/atlas_decor.png",
		"region": Vector2i(16, 16),
		"cells": [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0),
			Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
			Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2),
			Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3),
		],
		"collision": false,
	},
	{
		"id": 4,
		"texture": "res://assets/decor/atlas_decor_32.png",
		"region": Vector2i(32, 32),
		"cells": [Vector2i(0, 0), Vector2i(1, 0)],
		"collision": false,
	},
]


func _initialize() -> void:
	var ts := load(TILESET_PATH) as TileSet
	if ts == null:
		printerr("cannot load tileset: ", TILESET_PATH)
		quit(1)
		return

	# 遮光层：供 M2 锥形灯阴影。SDF 模式实测会把整锥光吞掉（疑与大面积实心遮光块相关），
	# 故用多边形模式（sdf_collision=false）
	if ts.get_occlusion_layers_count() == 0:
		ts.add_occlusion_layer(0)
	ts.set_occlusion_layer_sdf_collision(0, false)

	for zone in ZONES:
		var zone_id: int = zone["id"]
		if ts.has_source(zone_id):
			ts.remove_source(zone_id)
		var src := TileSetAtlasSource.new()
		src.texture = load(zone["texture"]) as Texture2D
		if src.texture == null:
			printerr("cannot load texture: ", zone["texture"])
			quit(1)
			return
		src.texture_region_size = zone["region"]
		for cell: Vector2i in zone["cells"]:
			src.create_tile(cell)
		ts.add_source(src, zone_id)
		# 碰撞必须在 source 挂到 TileSet 之后设置，否则 TileData 没有物理层上下文
		if zone["collision"]:
			for cell: Vector2i in zone["cells"]:
				var td := src.get_tile_data(cell, 0)
				td.set_collision_polygons_count(0, 1)
				td.set_collision_polygon_points(0, 0, PackedVector2Array(
					[Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
				var occluder := OccluderPolygon2D.new()
				occluder.closed = true
				occluder.polygon = PackedVector2Array(
					[Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
				td.set_occluder(0, occluder)
				# 防御：曾出现写入 16 个零点的退化多边形，立即自检
				var pts := td.get_collision_polygon_points(0, 0)
				if pts.size() != 4 or pts[2] != Vector2(8, 8):
					printerr("collision polygon write failed at ", cell)
					quit(1)
					return
		print("zone %d added: %s (%d cells)" % [zone_id, zone["texture"], (zone["cells"] as Array).size()])

	if ResourceSaver.save(ts, TILESET_PATH) != OK:
		printerr("save failed")
		quit(1)
		return
	print("tileset saved: ", TILESET_PATH)
	quit(0)
