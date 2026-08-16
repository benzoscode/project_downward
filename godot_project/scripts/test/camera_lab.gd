extends Node2D
## 镜头试验场：数字键 1-4 切换预设，定位跟随卡顿来源。
## 怀疑对象：物理帧更新相机 vs 渲染帧绘制（Godot 默认关物理插值）、pcam 像素吸附。

@onready var _pcam: Node2D = $Characters/Player/PhantomCamera2D
@onready var _player: CharacterBody2D = $Characters/Player
@onready var _camera: Camera2D = $RoomCamera
@onready var _hud: Label = $HUD/Label

var _preset: int = 1
var _preset_text: String = ""

# 预设：先全部重置为现状（基线），再叠加差异项，保证对比只变一个变量
func _apply_preset(p: int) -> void:
	_preset = p
	_set_interpolation(false)
	_pcam.set("snap_to_pixel", true)
	_pcam.set("follow_damping_value", Vector2(0.15, 0.15))
	match p:
		1:
			_preset_text = "1 baseline: phys-callback + snap + damp0.15"
		2:
			_set_interpolation(true)
			_preset_text = "2 physics interpolation ON"
		3:
			_pcam.set("snap_to_pixel", false)
			_preset_text = "3 snap_to_pixel OFF"
		4:
			_set_interpolation(true)
			_pcam.set("snap_to_pixel", false)
			_pcam.set("follow_damping_value", Vector2(0.10, 0.10))
			_preset_text = "4 interp ON + snap OFF + damp0.10"


# 根节点开关即可，子节点默认 INHERIT；同步写 ProjectSettings 让插件的抖动提示静默
func _set_interpolation(enabled: bool) -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON if enabled \
		else Node.PHYSICS_INTERPOLATION_MODE_OFF
	ProjectSettings.set_setting("physics/common/physics_interpolation", enabled)


func _ready() -> void:
	_apply_preset(1)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key >= KEY_1 and key <= KEY_4:
			_apply_preset(key - KEY_0)


func _process(_delta: float) -> void:
	_hud.text = "%s\nfps %d / physics %d tps\nplayer.x %.2f  cam.x %.2f" % [
		_preset_text,
		Engine.get_frames_per_second(),
		Engine.physics_ticks_per_second,
		_player.global_position.x,
		_camera.global_position.x,
	]
