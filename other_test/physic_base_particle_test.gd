extends Node2D


@export var force := 500.0

func _ready():
	for child in get_children():
		if child is RigidBody2D:
			var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
			child.apply_central_impulse(random_direction * force) 
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



# TODO : also then after that make it despawn
