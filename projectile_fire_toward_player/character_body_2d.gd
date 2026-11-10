
extends CharacterBody2D

@export var speed := 250.0
@export var jump_velocity := -400.0

@export var dash_speed := 700.0
@export var dash_duration := 0.18

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var jumps_left := 2
var is_dashing := false
var dash_timer := 0.0
var has_air_dashed := false


func _ready() -> void:
	show_direction("left")


func show_direction(direction: String):
	for x in $directions.get_children():
		x.visible = direction == x.name


func _physics_process(delta):

	# Reset abilities on ground
	if is_on_floor():
		jumps_left = 2
		has_air_dashed = false

	# Horizontal / vertical input
	var direction_x = Input.get_axis("left", "right")
	var direction_y = Input.get_axis("down", "up")

	# Jump / double jump
	if Input.is_action_just_pressed("ui_accept") and jumps_left > 0:
		velocity.y = jump_velocity
		jumps_left -= 1

	# Air dash
	if Input.is_action_just_pressed("dash") and not is_on_floor() and not has_air_dashed:

		var dash_direction = Vector2(direction_x, direction_y)

		# If no direction pressed, dash towards facing direction
		if dash_direction == Vector2.ZERO:
			dash_direction = Vector2(-1 if $directions/left.visible else 1, 0)

		dash_direction = dash_direction.normalized()

		velocity = dash_direction * dash_speed

		is_dashing = true
		has_air_dashed = true
		dash_timer = dash_duration

	# Dash duration
	if is_dashing:
		dash_timer -= delta

		if dash_timer <= 0:
			is_dashing = false

	# Gravity
	if not is_on_floor() and not is_dashing:
		velocity.y += gravity * delta

	# Horizontal movement
	if not is_dashing:
		velocity.x = direction_x * speed

	# Direction visuals
	if direction_x < 0:
		show_direction("left")
	if direction_x > 0:
		show_direction("right")
	if direction_y > 0:
		show_direction("up")
	if direction_y < 0:
		show_direction("down")

	# Attack
	if Input.is_action_just_pressed("attack"):
		for x in $directions.get_children():
			if x.visible and x.inside_area != null:
				x.damge(1)
			

	move_and_slide()
