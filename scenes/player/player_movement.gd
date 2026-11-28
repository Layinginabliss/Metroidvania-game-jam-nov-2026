extends Node

@export var body: CharacterBody2D
@export var knockback_force := 400.0

const RUN_SPEED := 450

# physics
const GRAVITY := 4000
const JUMP_VELOCITY := -1300
const MAX_FALL_SPEED := 2000.0 

var _can_move := true
var _is_jumping := false
var _is_running := false
var _is_moving := false
var _direction

func _ready():
	body.died.connect(func(): _can_move = false)

	
func _physics_process(_delta):
	if not _can_move:
		body.velocity = Vector2.ZERO
		return

	Globals.player_pos = body.global_position
	
	_direction = Input.get_axis("left", "right")

	# run detection
	_is_moving = abs(body.get_position_delta().x) >= 0.5 or abs(body.get_position_delta().y) >= 0.5
	_is_running = _direction != 0.0

	body.velocity.x = _direction * RUN_SPEED

	# apply gravity
	if not body.is_on_floor():
		body.velocity.y += GRAVITY * _delta
	else:
		if _is_jumping:
			_is_jumping = false

	# jump input
	if Input.is_action_just_pressed("jump") and body.is_on_floor() and Globals.player_control:
		body.velocity.y = JUMP_VELOCITY
		_is_jumping = true

	# clamp fall speed
	if body.velocity.y > MAX_FALL_SPEED:
		body.velocity.y = MAX_FALL_SPEED

	body.move_and_slide()
	
