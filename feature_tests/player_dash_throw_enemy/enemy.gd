extends CharacterBody2D

const SPEED = 300.0
const CHECK_INTERVAL = 1.0
const STUCK_THRESHOLD = 2.0

var direction := 1.0
var last_position := Vector2.ZERO


func _physics_process(delta: float) -> void:
	velocity.x = SPEED * direction
	move_and_slide()


func _on_check_for_stuck_timeout() -> void:
	var distance_moved = global_position.distance_to(last_position)

	if distance_moved < STUCK_THRESHOLD:
		direction *= -1.0

	last_position = global_position
