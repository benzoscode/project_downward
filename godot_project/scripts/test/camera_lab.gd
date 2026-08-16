extends Node2D
## 镜头试验场：数字键 1-5 切换预设，定位跟随卡顿来源。
## 依据：Phantom Camera FAQ（物理体目标需全局开物理插值）、插件 issue #648/#445。
## 预设 5 为对照组（硬锁定）：若它仍抖，则问题在帧 pacing/vsync 而非跟随逻辑。

@onready var _pcam: Node2D = $Characters/Player/PhantomCamera2D
@onready var _player: CharacterBody2D = $Characters/Player
@onready var _camera: Camera2D = $RoomCamera
@onready var _host: Node = $RoomCamera/PhantomCameraHost
@onready var _hud: Label = $HUD/Label

var _preset: int = 1
var _preset_text: String = ""

# host 的 interpolation_mode 枚举（插件定义）
const HOST_AUTO := 0
const HOST_IDLE := 1

# 预设：先全部重置为基线，再叠加差异项，保证对比只变一个变量
func _apply_preset(p: int) -> void:
	_preset = p
	_set_interpolation(false)
	_set_host_mode(HOST_AUTO)
	_pcam.set("snap_to_pixel", true)
	_pcam.set("follow_damping", true)
	_pcam.set("follow_damping_value", Vector2(0.15, 0.15))
	match p:
		1:
			_preset_text = "1 baseline: no-interp + AUTO + snap + damp0.15"
		2:
			# 插件官方推荐配置：插值开 + AUTO（相机物理帧更新，pcam 自身被插值）
			_set_interpolation(true)
			_preset_text = "2 interp ON + AUTO + snap + damp0.15"
		3:
			# 相机逻辑挪到渲染帧，直接读插值后的目标位置
			_set_interpolation(true)
			_set_host_mode(HOST_IDLE)
			_pcam.set("snap_to_pixel", false)
			_preset_text = "3 interp ON + hostIDLE + no-snap + damp0.15"
		4:
			_set_interpolation(true)
			_set_host_mode(HOST_IDLE)
			_pcam.set("snap_to_pixel", false)
			_pcam.set("follow_damping_value", Vector2(0.10, 0.10))
			_preset_text = "4 interp ON + hostIDLE + no-snap + damp0.10"
		5:
			# 对照组：硬锁定无阻尼，相机=目标位置。仍抖则查 vsync/帧 pacing
			_pcam.set("follow_damping", false)
			_preset_text = "5 control: glued, no damp, no interp"


# 根节点开关即可，子节点默认 INHERIT；同步写 ProjectSettings 让插件的抖动提示静默
func _set_interpolation(enabled: bool) -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON if enabled \
		else Node.PHYSICS_INTERPOLATION_MODE_OFF
	ProjectSettings.set_setting("physics/common/physics_interpolation", enabled)


# host 的 set_interpolation_mode 在 _active_pcam_2d 为空时会报错（插件 bug），
# 需等 pcam 激活后再设置；未激活时跳过，下个物理帧由 _apply_preset 重试
func _set_host_mode(mode: int) -> void:
	if _host.call("get_active_pcam") == null:
		return
	_host.set("interpolation_mode", mode)


func _ready() -> void:
	_apply_preset(1)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key >= KEY_1 and key <= KEY_5:
			_apply_preset(key - KEY_0)


func _process(_delta: float) -> void:
	_hud.text = "%s\nfps %d / physics %d tps / screen %.0fHz\nplayer.x %.2f  cam.x %.2f" % [
		_preset_text,
		Engine.get_frames_per_second(),
		Engine.physics_ticks_per_second,
		DisplayServer.screen_get_refresh_rate(),
		_player.global_position.x,
		_camera.global_position.x,
	]
