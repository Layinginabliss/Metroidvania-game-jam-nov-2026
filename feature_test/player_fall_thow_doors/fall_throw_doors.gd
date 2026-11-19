extends StaticBody2D

var waiting_to_cross_from_up_to_down: Node2D = null

func _physics_process(delta: float) -> void:
	if waiting_to_cross_from_up_to_down != null:
		if Input.is_action_just_pressed("down"):# not ui down but get down
			$CollisionShape2D.set_deferred("disabled", true)


func _on_from_up_to_down_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		waiting_to_cross_from_up_to_down = body


func _on_from_up_to_down_body_exited(body: Node2D) -> void:
	if body == waiting_to_cross_from_up_to_down:
		waiting_to_cross_from_up_to_down = null
		$CollisionShape2D.set_deferred("disabled", false)


func _on_from_down_to_up_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$CollisionShape2D.set_deferred("disabled", true)

	pass # Replace with function body.


func _on_from_down_to_up_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		$CollisionShape2D.set_deferred("disabled", false)
	pass # Replace with function body.
