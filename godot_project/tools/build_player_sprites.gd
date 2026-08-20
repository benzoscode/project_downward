extends SceneTree
## 把正式主角素材组进 player.tscn 的 AnimatedSprite2D。
## 动画集：idle/idle_lamp 8 帧横向（16×24）；run/run_lamp 10 帧纵向；
## climb 12 帧纵向（上爬，下爬倒放）；
## jump_rise/jump_fall 及灯版各 1 帧（16×26，2026-08-20 补画素材，比标准帧高 2px 为举手姿态）。
## 用法（godot_project/ 下）：& <godot_console.exe> --headless --script tools/build_player_sprites.gd

const DIR := "res://assets/characters/"


func _initialize() -> void:
	var packed := load("res://scenes/characters/player.tscn") as PackedScene
	var player := packed.instantiate()
	root.add_child(player)
	player.owner = null

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_strip(frames, &"idle", "char_player_idle.png", 8, Vector2i(16, 24), 6.0)
	_add_strip(frames, &"idle_lamp", "char_player_idle_lamp.png", 8, Vector2i(16, 24), 6.0)
	# 奔跑 10 帧纵向条带（2026-08-20 新素材，替换旧 8 帧横向版）
	_add_strip(frames, &"run", "char_player_run.png", 10, Vector2i(16, 24), 12.0, true)
	_add_strip(frames, &"run_lamp", "char_player_run_lamp.png", 10, Vector2i(16, 24), 12.0, true)
	# 攀爬 12 帧纵向条带（上爬序列，下爬由 player.gd 倒放；无灯光差分）
	_add_strip(frames, &"climb", "char_player_climb.png", 12, Vector2i(16, 24), 10.0, true)
	# 跳跃上升/下落（单帧，2026-08-20 素材）
	_add_strip(frames, &"jump_rise", "char_player_jump_rise.png", 1, Vector2i(16, 26), 5.0)
	_add_strip(frames, &"jump_rise_lamp", "char_player_jump_rise_lamp.png", 1, Vector2i(16, 26), 5.0)
	_add_strip(frames, &"jump_fall", "char_player_jump_fall.png", 1, Vector2i(16, 26), 5.0)
	_add_strip(frames, &"jump_fall_lamp", "char_player_jump_fall_lamp.png", 1, Vector2i(16, 26), 5.0)

	var sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.sprite_frames = frames
	sprite.animation = &"idle"

	var out := PackedScene.new()
	if out.pack(player) != OK or ResourceSaver.save(out, "res://scenes/characters/player.tscn") != OK:
		printerr("save failed")
		quit(1)
		return
	print("player.tscn sprites rebuilt")
	quit(0)


func _add_strip(frames: SpriteFrames, anim: StringName, file: String, count: int, frame_size: Vector2i, fps: float, vertical: bool = false) -> void:
	var tex := load(DIR + file) as Texture2D
	if tex == null:
		printerr("cannot load: ", file)
		quit(1)
		return
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, true)
	for i in range(count):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(0, i * frame_size.y, frame_size.x, frame_size.y) if vertical \
			else Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame(anim, at)
