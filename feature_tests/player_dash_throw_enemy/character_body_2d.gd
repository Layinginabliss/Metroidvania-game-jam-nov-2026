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

# Save original collision settings
var original_collision_layer: int
var original_collision_mask: int


func _ready() -> void:
	show_direction("left")

	original_collision_layer = collision_layer # layers don't really turn off on time
	original_collision_mask = collision_mask


func show_direction(direction: String):
	for x in $directions.get_children():
		x.visible = direction == x.name


func start_dash(direction: Vector2) -> void:
	
	if direction == Vector2.ZERO:
		direction = Vector2(-1 if $directions/left.visible else 1, 0)

	direction = direction.normalized()

	velocity = direction * dash_speed

	is_dashing = true
	dash_timer = dash_duration

	# Temporarily disable collision layer 2 and mask 2
	set_collision_layer_value(2, false)
	set_collision_mask_value(2, false)


func end_dash() -> void:
	is_dashing = false
	print('dashing')
	set_collision_layer_value(2,true)
	set_collision_mask_value(2,true)
	#collision_mask = original_collision_mask


func _physics_process(delta):
	print('dashing ended')
	# Reset abilities on ground
	if is_on_floor():
		jumps_left = 2
		has_air_dashed = false

	var direction_x = Input.get_axis("left", "right")
	var direction_y = Input.get_axis("down", "up")

	# Jump / double jump
	if Input.is_action_just_pressed("ui_accept") and jumps_left > 0:
		velocity.y = jump_velocity
		jumps_left -= 1

	# Dash: ground or air
	if Input.is_action_just_pressed("dash") and not is_dashing:
		if is_on_floor() or not has_air_dashed:

			var dash_direction = Vector2(direction_x, direction_y)

			start_dash(dash_direction)

			# Only consume air dash when airborne
			if not is_on_floor():
				has_air_dashed = true

	# Dash duration
	if is_dashing: # during dash remove other movenent inputs ?
		dash_timer -= delta

		if dash_timer <= 0:
			end_dash()

	# Gravity
	if not is_on_floor() and not is_dashing:
		velocity.y += gravity * delta

	# Normal movement
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
