extends Node2D
## 环境光源积木（M7）：熔岩裂缝/荧光苔藓等恒定光源的视觉+判定载体。
## 注册到 LightSystem，Boss 据此判定"玩家暴露在环境光下"（策划案 §二(四)3）。
## 判定 = 半径内 + 视线无地形遮挡（与遮光层一致）。

## 照亮半径（格），同时驱动视觉光晕大小与 Boss 感知判定
@export var radius_tiles: float = 4.0:
	set(value):
		radius_tiles = value
		if is_node_ready():
			_apply_radius()

var radius_px: float

@onready var _light: PointLight2D = $PointLight2D


func _ready() -> void:
	_apply_radius()
	LightSystem.register_ambient_light(self)


func _exit_tree() -> void:
	LightSystem.unregister_ambient_light(self)


func _apply_radius() -> void:
	radius_px = radius_tiles * 16.0
	# 径向贴图 64×64（半径 32px），缩放到照亮半径
	_light.texture_scale = radius_px / 32.0
