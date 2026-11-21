extends CharacterBody2D

var knock_back_force = 500
var gravity = 980.0

@export var run_this_current_state = true

func _ready() -> void:
	if not run_this_current_state:
		end_state()

func set_collition_mode(state):
	for x in get_children():
		if x is CollisionShape2D:
			x.set_deferred('disabled',not state)

func start_state(returns):
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

func damge(by):
	if not run_this_current_state : return 
	velocity = by.global_position.direction_to(global_position) * knock_back_force
	#print(by.global_position,' ',global_position)
	$knock_back_duration.start()

func _physics_process(delta: float) -> void:
	if not run_this_current_state : return 
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

func _on_knock_back_duration_timeout() -> void:
	if not run_this_current_state : return
	velocity = Vector2.ZERO
