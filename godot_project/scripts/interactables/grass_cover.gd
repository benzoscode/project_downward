extends Area2D
## 草丛光透（M6）：被玩家灯光照到时草丛变透明，显露出隐藏的通道入口。
## 纯视觉遮挡，无碰撞——秘密通道本来就能走，只是看不见（策划案 §三(九)）。

## 照亮时的透明度
@export var lit_alpha: float = 0.15

@onready var _sprite: Sprite2D = $Sprite2D


func _physics_process(_delta: float) -> void:
	var lit := LightSystem.is_point_lit(global_position)
	_sprite.modulate.a = lit_alpha if lit else 1.0


## 验证脚本用
func is_revealed() -> bool:
	return _sprite.modulate.a < 0.5
