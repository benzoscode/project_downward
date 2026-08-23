extends Node
## 音乐管理（Autoload: Music）：独立 Music 总线 + 循环播放 BGM，可切曲/淡入淡出。
## 默认曲为 bgm_main.mp3（2026-08-23 用户提供）。音量刻意调低，配 SFX（总线 -12dB）。
## 按房间切曲可后续扩展（按 RoomManager.current_room 映射曲目）。

const BUS := "Music"

var _player: AudioStreamPlayer
var _current: AudioStream = null
var _fade: Tween = null


func _ready() -> void:
	_ensure_bus()
	_player = AudioStreamPlayer.new()
	_player.bus = BUS
	add_child(_player)
	play("res://assets/audio/bgm/bgm_main.mp3")


func _ensure_bus() -> void:
	var idx := AudioServer.get_bus_index(BUS)
	if idx == -1:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS)
		AudioServer.set_bus_volume_db(idx, -12.0)
		_bus_idx = idx


var _bus_idx: int = 0


func play(path: String, fade_seconds: float = 0.0) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("Music: 无法加载 ", path)
		return
	play_stream(stream, fade_seconds)


## 用已加载的 AudioStream 播放（供运行时切曲）
func play_stream(stream: AudioStream, fade_seconds: float = 0.0) -> void:
	# BGM 循环：mp3/wav 等常见类型都有 loop 属性，统一开启
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	if fade_seconds > 0.0:
		if _fade != null and _fade.is_valid():
			_fade.kill()
		_player.volume_db = -60.0
		_fade = create_tween()
		_fade.tween_property(_player, "volume_db", 0.0, fade_seconds)
	_player.stream = stream
	_player.play()


func stop() -> void:
	_player.stop()


func is_playing() -> bool:
	return _player.playing
