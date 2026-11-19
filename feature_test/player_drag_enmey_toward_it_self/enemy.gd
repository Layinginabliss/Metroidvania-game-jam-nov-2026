extends CharacterBody2D

@onready var head = $head
@onready var two = $two

var gravity = 980.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += Vector2.DOWN  * gravity * delta

	move_and_slide()
	
