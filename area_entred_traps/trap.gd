extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if something_in != null:
		var body = something_in
			#print('here')
		$face.look_at(body.global_position)
		
		var direction = $face.global_position.direction_to(body.global_position) * push_force # $face.global_position.distance_to(body.global_position)
		#print(direction)
		## Add slight random variation (-15 to +15 degrees)
		#direction = direction.rotated(deg_to_rad(randf_range(-15.0, 15.0)))
#
		body.push_in_this_direction(direction)

var push_force = 100

var something_in = null

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		something_in = body

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		something_in = null
	pass # Replace with function body.
