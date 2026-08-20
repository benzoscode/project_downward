extends SceneTree
## 把正式主角素材组进 player.tscn 的 AnimatedSprite2D（M10 前的实装替换，2026-08-17）。
## 动画集：idle/idle_lamp/run/run_lamp 各 8 帧；跳跃上升/下落各 1 帧 ×有灯/无灯（2026-08-20 实装）。
## 用法（godot_project/ 下）：& <godot_console.exe> --headless --script tools/build_player_sprites.gd

const FRAME_SIZE := Vector2i(16, 24)
const JUMP_FRAME_SIZE := Vector2i(16, 26)
const DIR := "res://assets/characters/"


func _initialize() -> void:
	var packed := load("res://scenes/characters/player.tscn") as PackedScene
	var player := packed.instantiate()
	root.add_child(player)
	player.owner = null

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_strip(frames, &"idle", "char_player_idle.png", 8, 6.0)
	_add_strip(frames, &"idle_lamp", "char_player_idle_lamp.png", 8, 6.0)
	_add_strip(frames, &"run", "char_player_run.png", 8, 10.0)
	_add_strip(frames, &"run_lamp", "char_player_run_lamp.png", 8, 10.0)
	# 跳跃上升/下落各一张（2026-08-20 新素材，16×26 比常规帧高 2px，脚底对齐误差 ±1px 可接受）
	_add_strip(frames, &"jump_rise", "char_player_jump_rise.png", 1, 5.0, JUMP_FRAME_SIZE)
	_add_strip(frames, &"jump_fall", "char_player_jump_fall.png", 1, 5.0, JUMP_FRAME_SIZE)
	_add_strip(frames, &"jump_rise_lamp", "char_player_jump_rise_lamp.png", 1, 5.0, JUMP_FRAME_SIZE)
	_add_strip(frames, &"jump_fall_lamp", "char_player_jump_fall_lamp.png", 1, 5.0, JUMP_FRAME_SIZE)

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


func _add_strip(frames: SpriteFrames, anim: StringName, file: String, count: int, fps: float, frame_size: Vector2i = FRAME_SIZE) -> void:
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
		at.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame(anim, at)
