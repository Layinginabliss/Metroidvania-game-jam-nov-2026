extends RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	duplicate_around(10)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func duplicate_around(amount: int) -> void:
	var original = self
	var angle_step = 360.0 / amount

	for i in range(amount):
		var new_body = original.duplicate()

		new_body.rotation_degrees = angle_step * i

		add_child(new_body)
