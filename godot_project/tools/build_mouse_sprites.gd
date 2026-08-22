extends SceneTree
## 把鼠鼠正式素材组进 mouse.tscn 的 AnimatedSprite2D（2026-08-20）。
## 动画集：idle 12 帧 / run 9 帧（27×9 纵向条带）；jump_rise/jump_fall 各 1 帧（20×20 整图）。
## 用法（godot_project/ 下）：& <godot_console.exe> --headless --script tools/build_mouse_sprites.gd

const DIR := "res://assets/characters/"


func _initialize() -> void:
	var packed := load("res://scenes/characters/mouse.tscn") as PackedScene
	var mouse := packed.instantiate()
	root.add_child(mouse)
	mouse.owner = null

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_strip(frames, &"idle", "char_mouse_idle.png", 12, Vector2i(27, 9), 8.0)
	_add_strip(frames, &"run", "char_mouse_run.png", 9, Vector2i(27, 9), 12.0)
	# 跳跃上升/下降整图单帧（与主角跳跃同处理方式，2026-08-20 素材）
	_add_strip(frames, &"jump_rise", "char_mouse_jump_rise.png", 1, Vector2i(20, 20), 5.0)
	_add_strip(frames, &"jump_fall", "char_mouse_jump_fall.png", 1, Vector2i(20, 20), 5.0)

	var sprite := mouse.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.sprite_frames = frames
	sprite.animation = &"idle"

	var out := PackedScene.new()
	if out.pack(mouse) != OK or ResourceSaver.save(out, "res://scenes/characters/mouse.tscn") != OK:
		printerr("save failed")
		quit(1)
		return
	print("mouse.tscn sprites rebuilt")
	quit(0)


func _add_strip(frames: SpriteFrames, anim: StringName, file: String, count: int, frame_size: Vector2i, fps: float) -> void:
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
		at.region = Rect2(0, i * frame_size.y, frame_size.x, frame_size.y)
		frames.add_frame(anim, at)
