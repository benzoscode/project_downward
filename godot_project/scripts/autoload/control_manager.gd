extends Node
## 双体控制管理（Autoload: ControlManager，M5）
## Q 召唤/收回老鼠（需召唤哨），R 在玩家/老鼠间切换操控，老鼠死亡 5 秒冷却。
## 策划案 §二(二)3：切换时玩家静止、相机切到老鼠、切回后老鼠停留原地。

## 老鼠死亡后的重新召唤冷却（秒），策划案定 5 秒
@export var resummon_cooldown: float = 5.0

const MOUSE_SCENE := "res://scenes/characters/mouse.tscn"

var player: Player = null
var mouse: Mouse = null
var controlling_mouse: bool = false
var _cooldown: float = 0.0


func register_player(p: Player) -> void:
	player = p


## 验证/调试查询
func is_mouse_out() -> bool:
	return mouse != null


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if player == null:
		return
	if Input.is_action_just_pressed(&"whistle") and GameState.has_whistle:
		if mouse == null and _cooldown <= 0.0:
			_summon()
		elif mouse != null:
			_recall()
	if Input.is_action_just_pressed(&"switch_control") and mouse != null:
		_switch()


func _summon() -> void:
	mouse = (load(MOUSE_SCENE) as PackedScene).instantiate() as Mouse
	mouse.position = player.position + Vector2(0, 7) # 老鼠矮，贴地出生
	player.get_parent().add_child(mouse)


func _recall() -> void:
	if controlling_mouse:
		_switch()
	mouse.queue_free()
	mouse = null


func _switch() -> void:
	controlling_mouse = not controlling_mouse
	player.control_active = not controlling_mouse
	mouse.control_active = controlling_mouse
	# 相机切换：老鼠 pcam 优先级压过玩家（10）即被接管，切回则还原
	mouse.set_pcam_priority(11 if controlling_mouse else 0)


## 老鼠死亡：消失 + 冷却（策划案 §二(二)3）
func on_mouse_died() -> void:
	_recall()
	_cooldown = resummon_cooldown


## 主动收回（房间切换等）：不进入死亡冷却。RoomManager 转场时调用。
func force_recall() -> void:
	if mouse != null:
		_recall()


## 验证脚本用：直接读冷却剩余
func get_cooldown() -> float:
	return _cooldown
