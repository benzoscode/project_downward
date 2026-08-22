extends Node2D
## 二段跳气流粒子（策划案 §二(二)2 羽翎靴外观：跳跃拖出微弱气流）。播完自毁。


func _ready() -> void:
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	sprite.animation_finished.connect(queue_free)
	sprite.play(&"puff")
