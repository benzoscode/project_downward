extends AnimatableBody2D
## 交替平台（M6）：A/B 两组按周期交替显隐，时间基准全局同步（同房间所有平台对齐）。
## 消失只撤碰撞与贴图，站上面的角色自然下落（不做额外位移，避免挤压判定）。

## 显隐周期（秒）：每组各亮一半周期
@export var period: float = 2.0
## false=A 组（周期前半亮），true=B 组（后半亮）
@export var group_b: bool = false

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D


func _physics_process(_delta: float) -> void:
	var t := fmod(Time.get_ticks_msec() / 1000.0, period)
	var a_on := t < period * 0.5
	var on := not a_on if group_b else a_on
	_collision.disabled = not on
	_sprite.modulate.a = 1.0 if on else 0.15


## 验证脚本用
func is_solid() -> bool:
	return not _collision.disabled
