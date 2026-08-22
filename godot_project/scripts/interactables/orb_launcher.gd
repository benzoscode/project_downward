@tool
extends Node2D
## 光球发射器（2026-08-18 用户需求）：收到 MechanismBus 触发（listen_id）即沿发射方向射出光球，
## 冷却 1 秒可再发（按钮可连按）。光球初速沿方向，之后受衰减重力缓降，life_time 秒消散。
## 方向用节点旋转表达（编辑器里转发射器即可），@tool 画方向箭头。

## 触发的总线 ID（通常由点动按钮 target_id 指过来）
@export var listen_id: StringName
## 发射初速（px/秒）
@export var launch_speed: float = 120.0
## 发射冷却（秒），用户需求定 1s
@export var cooldown: float = 1.0
## 光球存活秒数，用户需求示例 10s
@export var orb_lifetime: float = 10.0
## 光球颜色（"有颜色的光球"）
@export var orb_tint: Color = Color(0.6, 0.85, 1.0)

const ORB_SCENE := "res://scenes/interactables/light_orb.tscn"

var _cooldown_left: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	MechanismBus.triggered.connect(_on_triggered)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_cooldown_left = maxf(0.0, _cooldown_left - delta)


func _on_triggered(id: StringName) -> void:
	if id != listen_id or _cooldown_left > 0.0:
		return
	_cooldown_left = cooldown
	Sfx.play(&"orb_launch")
	var orb := (load(ORB_SCENE) as PackedScene).instantiate() as LightOrb
	orb.setup(Vector2.RIGHT.rotated(global_rotation) * launch_speed, orb_tint, orb_lifetime)
	# 挂到当前场景根（房间/main 皆在原点，先入树再设全局坐标避免父级变换干扰）
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(orb)
	orb.global_position = global_position


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	# 方向箭头：+X 即发射方向
	draw_line(Vector2.ZERO, Vector2(28, 0), Color(0.6, 0.85, 1, 0.8), 1.5)
	draw_line(Vector2(28, 0), Vector2(22, -4), Color(0.6, 0.85, 1, 0.8), 1.5)
	draw_line(Vector2(28, 0), Vector2(22, 4), Color(0.6, 0.85, 1, 0.8), 1.5)
