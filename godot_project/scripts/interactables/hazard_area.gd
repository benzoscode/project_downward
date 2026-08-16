extends Area2D
## 危险区域（地刺等）：玩家触碰即死，回房间出生点。
## 死亡惩罚与状态保留规则见策划案 §一。


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		(body as Player).die()
	elif body.is_in_group(&"mouse"):
		(body as Mouse).die()
