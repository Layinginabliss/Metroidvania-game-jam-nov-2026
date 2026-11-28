extends Node

@export var body: CharacterBody2D

const RUN_SPEED := 450

# physics
const GRAVITY := 4000
const JUMP_VELOCITY := -1300
const MAX_FALL_SPEED := 2000.0 

var _can_move := true
var _is_jumping := false
var _is_running := false
var _is_moving := false

func _ready():
	body.died.connect(func(): _can_move = false)

	
func _physics_process(_delta):
	if not _can_move:
		body.velocity = Vector2.ZERO
		return

	Globals.player_pos = body.global_position

	# run detection
	_is_moving = abs(body.get_position_delta().x) >= 0.5 or abs(body.get_position_delta().y) >= 0.5
	_is_running = body.direction != 0.0

	# horizontal movement knockback overrides player control otherwise run speed
	if body.is_knockback:
		body.velocity.x = body.knockback_dir.x * body.knockback_force
	elif body.is_attacking:
		body.velocity.x = 0.0
	else:
		body.velocity.x = body.direction * RUN_SPEED

	# apply gravity
	if not body.is_on_floor():
		body.velocity.y += GRAVITY * _delta
	else:
		if _is_jumping:
			_is_jumping = false

	# jump input
	if Input.is_action_just_pressed("jump") and body.is_on_floor() and Globals.player_control and not body.is_knockback and not body.is_attacking:
		body.velocity.y = JUMP_VELOCITY
		_is_jumping = true

	# clamp fall speed
	if body.velocity.y > MAX_FALL_SPEED:
		body.velocity.y = MAX_FALL_SPEED

	body.move_and_slide()
