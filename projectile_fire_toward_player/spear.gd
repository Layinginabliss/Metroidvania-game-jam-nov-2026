extends Area2D

var go = false
var speed = 1000.0

func _process(delta: float) -> void:
	if go:
		var forward = global_transform.x
		global_position += forward * speed * delta
