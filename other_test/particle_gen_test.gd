extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	duplicate_around(20)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@export var starting_angle = 180.0

func duplicate_around(amount: int) -> void:
	var original = $RigidBody2D
	var angle_step = 360.0 / amount

	for i in range(amount):
		
		if angle_step * i > starting_angle:
			
			var new_body = original.duplicate() # get collition shape position # and ridigtin body postion add force tward each...

			new_body.rotation_degrees = angle_step * i

			add_child(new_body)
