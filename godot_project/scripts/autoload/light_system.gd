extends Node
## 光照判定系统（Autoload: LightSystem）
## 提供"某点是否被玩家灯光照到"查询，供光敏水晶、Boss 感知等复用（策划案 §二(二)1）。
## 判定 = 射程内 + 锥形角内 + 视线无遮挡（物理射线，与地形碰撞同层）。

var _lamp: Node2D = null
# 环境光源（熔岩裂缝/荧光苔藓等，ambient_light.tscn 注册），供 Boss 判定"玩家暴露在环境光"
var _ambient_lights: Array[Node2D] = []


func register_lamp(lamp: Node2D) -> void:
	_lamp = lamp


func unregister_lamp(lamp: Node2D) -> void:
	if _lamp == lamp:
		_lamp = null


func register_ambient_light(light: Node2D) -> void:
	if not _ambient_lights.has(light):
		_ambient_lights.append(light)


func unregister_ambient_light(light: Node2D) -> void:
	_ambient_lights.erase(light)


## 玩家灯是否开启（Boss 感知用，策划案 §二(四)3：开灯即暴露）
func is_lamp_on() -> bool:
	return _lamp != null and _lamp.get("lamp_on")


## 两点间视线是否无地形遮挡（碰撞层 1，与遮光几何一致）。仅在物理帧内调用。
func has_clear_line(from: Vector2, to: Vector2) -> bool:
	var space := get_tree().root.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	return space.intersect_ray(query).is_empty()


## 查询点是否被任一环境光源照亮：半径内 + 视线无遮挡
func is_point_lit_ambient(point: Vector2) -> bool:
	for light in _ambient_lights:
		if not is_instance_valid(light):
			continue
		var to_point: Vector2 = point - light.global_position
		if to_point.length() > light.get("radius_px"):
			continue
		if has_clear_line(light.global_position, point):
			return true
	return false


## 查询点是否处于玩家锥形灯照亮范围。灯关/未拾取灯时恒 false。
func is_point_lit(point: Vector2) -> bool:
	if _lamp == null or not _lamp.get("lamp_on"):
		return false
	var origin: Vector2 = _lamp.global_position
	var to_point := point - origin
	var range_px: float = _lamp.get("range_px")
	if to_point.length() > range_px:
		return false
	var forward := Vector2.RIGHT.rotated(_lamp.global_rotation)
	if absf(forward.angle_to(to_point)) > _lamp.get("half_angle"):
		return false
	# 视线遮挡：射线撞地形碰撞（与 LightOccluder 同几何）则判定照不到
	var space := _lamp.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(origin, point, 1)
	return space.intersect_ray(query).is_empty()
