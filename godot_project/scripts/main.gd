extends Node
## 游戏启动场景（M8）：从第 1 房间开始游戏。
## 各测试/演示场景仍可 F6 独立运行（RoomManager 会收养场景自带玩家）。


func _ready() -> void:
	RoomManager.goto_room("res://scenes/rooms/room_01.tscn", &"default")
