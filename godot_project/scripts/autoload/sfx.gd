extends Node
## 音效管理（Autoload: Sfx）：独立 SFX 总线 + 播放器池，任意积木/角色 `Sfx.play("jump")` 即可发声。
## 占位音源为生成的短促 WAV（assets/audio/sfx/），替换 = 同名覆盖，代码零改动。
## 音量刻意压低、短促，避免喧宾夺主（用户 2026-08-20 要求）。

## 总线名；播放器都挂到该总线，统一音量控制
const BUS := "SFX"
## 播放器池大小，支持多音效叠加
const POOL_SIZE := 24

const SFX: Dictionary = {
	&"jump": preload("res://assets/audio/sfx/jump.wav"),
	&"double_jump": preload("res://assets/audio/sfx/double_jump.wav"),
	&"land": preload("res://assets/audio/sfx/land.wav"),
	&"lamp_on": preload("res://assets/audio/sfx/lamp_on.wav"),
	&"lamp_off": preload("res://assets/audio/sfx/lamp_off.wav"),
	&"whistle": preload("res://assets/audio/sfx/whistle.wav"),
	&"switch_control": preload("res://assets/audio/sfx/switch_control.wav"),
	&"interact": preload("res://assets/audio/sfx/interact.wav"),
	&"door_open": preload("res://assets/audio/sfx/door_open.wav"),
	&"door_close": preload("res://assets/audio/sfx/door_close.wav"),
	&"pickup": preload("res://assets/audio/sfx/pickup.wav"),
	&"chest_open": preload("res://assets/audio/sfx/chest_open.wav"),
	&"plate_press": preload("res://assets/audio/sfx/plate_press.wav"),
	&"crystal_activate": preload("res://assets/audio/sfx/crystal_activate.wav"),
	&"orb_launch": preload("res://assets/audio/sfx/orb_launch.wav"),
	&"gem_embed": preload("res://assets/audio/sfx/gem_embed.wav"),
	&"gate_open": preload("res://assets/audio/sfx/gate_open.wav"),
	&"checkpoint": preload("res://assets/audio/sfx/checkpoint.wav"),
	&"boss_roar": preload("res://assets/audio/sfx/boss_roar.wav"),
	&"player_die": preload("res://assets/audio/sfx/player_die.wav"),
	&"lever": preload("res://assets/audio/sfx/lever.wav"),
}

var _bus_index: int
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0


func _ready() -> void:
	_ensure_bus()
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = BUS
		p.volume_db = -6.0 # 整体压低
		add_child(p)
		_pool.append(p)


func _ensure_bus() -> void:
	var idx := AudioServer.get_bus_index(BUS)
	if idx == -1:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS)
		# 默认音量略低于 Master，配氛围
		AudioServer.set_bus_volume_db(idx, -8.0)
	_bus_index = idx


## 播放音效（name 为注册名）。volume_override 可临时调音量（-20..0）。
func play(sfx: StringName) -> void:
	if not SFX.has(sfx):
		push_warning("Sfx: 未知音效 ", sfx)
		return
	var stream: AudioStream = SFX[sfx]
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.play()
