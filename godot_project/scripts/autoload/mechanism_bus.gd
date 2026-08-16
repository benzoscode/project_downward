extends Node
## 机关通信总线（Autoload: MechanismBus）
## 触发源（按钮/压力板）与接收方（门/平台）仅以 StringName ID 关联，禁止节点直引。
## 设计决策见 docs/decisions.md 2026-08-16 条目；策划案 §一：死亡后机关状态保留，
## 故状态存于本单例，不随房间/角色重置。

## 触发源被激活（按钮按下、压力板踩下）
signal triggered(id: StringName)
## 触发源解除（可重复按钮再按、压力板离开）
signal released(id: StringName)

var _states: Dictionary = {}


func trigger(id: StringName) -> void:
	if _states.get(id, false):
		return
	_states[id] = true
	triggered.emit(id)


func release(id: StringName) -> void:
	if not _states.get(id, false):
		return
	_states[id] = false
	released.emit(id)


## 接收方初始化时查询当前状态（门重生后保持开态，见策划案 §一）
func is_triggered(id: StringName) -> bool:
	return _states.get(id, false)


## 仅验证脚本/调试使用：清空全部机关状态
func reset_all() -> void:
	_states.clear()
