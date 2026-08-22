extends AnimatableBody2D
## 交替平台（M6）：A/B 两组按周期交替显隐，时间基准全局同步（同房间所有平台对齐）。
## 2026-08-20 换正式素材：显现/消失两套 16×16 拼块（左/中/右），消失态撤碰撞但贴图保留半透明。
## 消失只撤碰撞与贴图，站上面的角色自然下落（不做额外位移，避免挤压判定）。

## 显隐周期（秒）：每组各亮一半周期
@export var period: float = 2.0
## false=A 组（周期前半亮），true=B 组（后半亮）
@export var group_b: bool = false
## 平台宽度（格数），左/中/右拼块铺开
@export var width_tiles: int = 3:
	set(value):
		width_tiles = maxi(1, value)
		_apply_geometry()

const TILE := 16.0

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _pieces: Array[Sprite2D] = []


func _ready() -> void:
	_apply_geometry()


func _physics_process(_delta: float) -> void:
	var t := fmod(Time.get_ticks_msec() / 1000.0, period)
	var a_on := t < period * 0.5
	var on := not a_on if group_b else a_on
	_collision.disabled = not on
	for piece in _pieces:
		piece.texture = piece.get_meta(&"tex_on") if on else piece.get_meta(&"tex_off")
		piece.modulate.a = 1.0 if on else 0.15


## 验证脚本用
func is_solid() -> bool:
	return not _collision.disabled


func _apply_geometry() -> void:
	if not is_node_ready():
		return
	(_collision.shape as RectangleShape2D).size = Vector2(width_tiles * TILE, 8)
	_collision.position = Vector2(width_tiles * TILE * 0.5, 4)
	# 重建拼块：左/中/右 × 显现/消失，共 6 张
	for piece in _pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	_pieces.clear()
	var tex_dir := "res://assets/props/"
	for i in range(width_tiles):
		var edge := &"left" if i == 0 else (&"right" if i == width_tiles - 1 else &"mid")
		var sprite := Sprite2D.new()
		var tex_on := load(tex_dir + "platform_alt_solid_" + edge + ".png") as Texture2D
		var tex_off := load(tex_dir + "platform_alt_ghost_" + edge + ".png") as Texture2D
		sprite.texture = tex_on
		sprite.set_meta(&"tex_on", tex_on)
		sprite.set_meta(&"tex_off", tex_off)
		sprite.position = Vector2(i * TILE + TILE * 0.5, 0)
		sprite.z_index = -1
		add_child(sprite)
		_pieces.append(sprite)
