extends Node
## 控制台命令验证（2026-08-23）：道具获取/别名/清空/全给/未知命令。
## 用法（godot_project/ 下）：
##   & <godot_console.exe> --headless res://scenes/test/verify_host.tscn -- res://tools/verify/verify_console.gd

var _failures: int = 0
var _passed: int = 0


func _ready() -> void:
	_run_tests()


func _check(test: String, ok: bool, detail: String = "") -> void:
	if ok:
		_passed += 1
		print("[PASS] ", test)
	else:
		_failures += 1
		printerr("[FAIL] ", test, " | ", detail)


func _clear_state() -> void:
	GameState.has_lamp = false
	GameState.has_boots = false
	GameState.has_whistle = false
	GameState.has_key = false
	GameState.gems.clear()


func _run_tests() -> void:
	_clear_state()
	await _physics(0)

	# get_item 英文名
	_clear_state()
	Console._run("get_item lamp")
	await _physics(0)
	_check("T1 get_item lamp", GameState.has_lamp, "has_lamp=%s" % GameState.has_lamp)

	# 中文别名 翡翠 → gem_jade
	_clear_state()
	Console._run("get_item 翡翠")
	await _physics(0)
	_check("T2 中文别名翡翠→gem_jade", GameState.gems.has(&"gem_jade"), "gems=%s" % [GameState.gems])

	# 未知道具 → 报错不崩
	_clear_state()
	Console._run("get_item nope")
	await _physics(0)
	_check("T3 未知道具不崩溃", true, "")

	# give_all 全部道具+三宝石
	_clear_state()
	Console._run("give_all")
	await _physics(0)
	var all_got: bool = GameState.has_lamp and GameState.has_boots and GameState.has_whistle \
		and GameState.has_key and GameState.gems.size() == 3
	_check("T4 give_all", all_got, "gems=%s" % [GameState.gems])

	# clear_items 清空
	Console._run("clear_items")
	await _physics(0)
	_check("T5 clear_items", not GameState.has_lamp and GameState.gems.is_empty(), "gems=%s" % [GameState.gems])

	print("VERIFY RESULT: %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _physics(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame
