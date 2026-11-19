extends Area2D


var apply_knockback = null
@export var knock_back_force = 100
var _gravity = 0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('player'):
		print('here')
		_gravity = body.gravity
		#body.gravity = 0.0
		body.velocity = global_position.direction_to(body.global_position) * knock_back_force
		apply_knockback = body
		body.deactive = true
		$knock_back_lasting_time.start()
		#should we deactivate ?
	pass # Replace with function body.


func _on_nock_back_lasting_time_timeout() -> void:
	if not apply_knockback == null:
		$recovery_time.start()
		#apply_knockback.gravity = _gravity
	pass # Replace with function body.


func _on_recovery_time_timeout() -> void:
	apply_knockback.deactive = false
	apply_knockback = null
	pass # Replace with function body.
