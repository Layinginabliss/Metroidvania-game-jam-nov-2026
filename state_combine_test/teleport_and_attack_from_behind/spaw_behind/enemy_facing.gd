

extends CharacterBody2D
@export var run_this_current_state = true

@export var speed := 200.0

var moving_direction := Vector2.RIGHT
var last_pos := Vector2.ZERO
var stuck_tol := 1


func set_collition_mode(state):
	for x in get_children():
		if x is CollisionShape2D:
			x.set_deferred('disabled',not state)

func start_state(returns):
	#$right/check_for_player_coll. # TODO : the collition of teleport need be activated when the event starts
	global_position = returns
	#print('starting ',self.name) # as node...
	set_collition_mode(true)
	visible = true
	run_this_current_state = true

func end_state():
	set_collition_mode(false)
	
	visible = false
	run_this_current_state = false
	return global_position

func _ready() -> void:
	randomize()
	moving_direction = Vector2.LEFT if randf() < 0.5 else Vector2.RIGHT
	last_pos = global_position

	if not run_this_current_state:
		end_state()


func _physics_process(delta: float) -> void:
	if not run_this_current_state : return
	# Arrow-key override


	#if input_direction != Vector2.ZERO:
		#moving_direction = input_direction

	#set random left or right movment

	# Automatic movement
	velocity = moving_direction * speed
	move_and_slide()

	update_teleport_directions(moving_direction)


func update_teleport_directions(direction: Vector2):
	if not run_this_current_state : return
	if direction.x > 0:
		$right.visible = true
		$left.visible = false
	elif direction.x < 0:
		$right.visible = false
		$left.visible = true


func get_posiible_teleport_position():
	if not run_this_current_state : return
	if $right.visible:
		return $right.global_position
	if $left.visible:
		return $left.global_position
	return null


func get_posiible_to_teleport():
	if not run_this_current_state : return
	if $right.visible:
		return $right.inside_bodies.is_empty()
	if $left.visible:
		return $left.inside_bodies.is_empty()
	return false


func _on_check_if_stuck_timeout() -> void:
	if not run_this_current_state : return
	if global_position.distance_to(last_pos) < stuck_tol:
		moving_direction *= -1

	last_pos = global_position
