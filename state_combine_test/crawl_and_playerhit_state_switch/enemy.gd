extends CharacterBody2D


@export var SPEED = 300.0

var crawl_toward : Node2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta	
	move_and_slide()

func _on_cool_down_timeout() -> void:
	if not crawl_toward == null:
		velocity = global_position.direction_to(crawl_toward.global_position) * SPEED

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('player'):
		crawl_toward = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group('player'):
		crawl_toward = null
