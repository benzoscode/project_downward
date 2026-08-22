extends SceneTree
## 把 Boss 正式素材组进 boss.tscn 的 AnimatedSprite2D（2026-08-20）。
## 动画集：idle 4 帧 / move 4 帧 / attack 6 帧（128×128 纵向条带）。
## 用法（godot_project/ 下）：& <godot_console.exe> --headless --script tools/build_boss_sprites.gd

const DIR := "res://assets/characters/"
const FRAME := Vector2i(128, 128)


func _initialize() -> void:
	var packed := load("res://scenes/characters/boss.tscn") as PackedScene
	var boss := packed.instantiate()
	root.add_child(boss)
	boss.owner = null

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_strip(frames, &"idle", "char_boss_idle.png", 4, 6.0)
	_add_strip(frames, &"move", "char_boss_move.png", 4, 8.0)
	_add_strip(frames, &"attack", "char_boss_attack.png", 6, 10.0)

	var sprite := boss.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.sprite_frames = frames
	sprite.animation = &"idle"

	var out := PackedScene.new()
	if out.pack(boss) != OK or ResourceSaver.save(out, "res://scenes/characters/boss.tscn") != OK:
		printerr("save failed")
		quit(1)
		return
	print("boss.tscn sprites rebuilt")
	quit(0)


func _add_strip(frames: SpriteFrames, anim: StringName, file: String, count: int, fps: float) -> void:
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
		at.region = Rect2(0, i * FRAME.y, FRAME.x, FRAME.y)
		frames.add_frame(anim, at)
