extends CharacterBody2D

var knock_back_force = 500
var gravity = 980.0

func damge(by):
	velocity = by.global_position.direction_to(global_position) * knock_back_force
	#print(by.global_position,' ',global_position)
	$knock_back_duration.start()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

func _on_knock_back_duration_timeout() -> void:
	velocity = Vector2.ZERO
