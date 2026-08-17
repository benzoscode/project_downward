extends Node
## 全局游戏状态（Autoload: GameState）
## 道具永久持有、无消耗无升级，见策划案 §二(二)。
## 死亡惩罚为回检查点重来，机关状态保留，见策划案 §一。

## 获得道具（照明灯/羽翎靴/召唤哨/宝石）时发出，供 UI 反馈与房间逻辑订阅
signal item_acquired(item: StringName)
## 检查点更新（进入新房间入口时）
signal checkpoint_updated(room: StringName, position: Vector2)

var has_lamp: bool = false
var has_boots: bool = false
var has_whistle: bool = false
## 第 4 房间宝箱钥匙，开第 3 房间右上角钥匙门（策划案 §三(三)/(四)）
var has_key: bool = false
## 已收集宝石：翡翠/琥珀/紫金，用于第 12 房间三宝石之门（策划案 §三(十二)）
var gems: Array[StringName] = []

var current_room: StringName = &""
var checkpoint_room: StringName = &""
var checkpoint_position: Vector2 = Vector2.ZERO


func acquire_item(item: StringName) -> void:
	match item:
		&"lamp":
			has_lamp = true
		&"boots":
			has_boots = true
		&"whistle":
			has_whistle = true
		&"key":
			has_key = true
		_:
			# 只认 gem_ 前缀，其他道具不得误入宝石列表
			if item.begins_with("gem_") and not gems.has(item):
				gems.append(item)
	item_acquired.emit(item)


func set_checkpoint(room: StringName, position: Vector2) -> void:
	checkpoint_room = room
	checkpoint_position = position
	checkpoint_updated.emit(room, position)
