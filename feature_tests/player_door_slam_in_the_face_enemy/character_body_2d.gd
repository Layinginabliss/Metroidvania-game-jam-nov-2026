
extends CharacterBody2D

@export var speed := 250.0
@export var jump_velocity := -400.0

@export var dash_speed := 1000.0
@export var dash_duration := 0.2

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var jumps_left := 2
var is_dashing := false
var dash_timer := 0.0
var has_air_dashed := false


func _ready() -> void:
	show_direction("left")


func show_direction(direction: String) -> void:
	for x in $directions.get_children():
		x.visible = direction == x.name

func animate_direction(dir: Vector2) -> void:
	if dir.x < 0: show_direction("left")
	if dir.x > 0: show_direction("right")
	if dir.y > 0: show_direction("up")
	if dir.y < 0: show_direction("down")

func attack() -> void:
	for x in $directions.get_children():
		if x.visible and x.inside_area != null:
			x.damage(1)

func air_dash(direction: Vector2, delta: float) -> void:
	if Input.is_action_just_pressed("dash") and not is_on_floor() and not has_air_dashed:
		
		var dash_direction = direction
		
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

func normal_move(direction_x: float, delta: float) -> void:
	# Gravity
	if not is_on_floor() and not is_dashing:
		velocity.y += gravity * delta
	
	# Horizontal movement
	if not is_dashing:
		velocity.x = direction_x * speed

func jump() -> void:
	velocity.y = jump_velocity
	jumps_left -= 1


func _physics_process(delta: float) -> void:

	# Reset abilities on ground
	if is_on_floor():
		jumps_left = 2
		has_air_dashed = false

	# Horizontal / vertical input
	var direction_x = Input.get_axis("left", "right")
	var direction_y = Input.get_axis("down", "up")
	var direction = Vector2(direction_x, direction_y)

	# Jump / double jump
	if Input.is_action_just_pressed("ui_accept") and jumps_left > 0: jump()
	
	air_dash(direction, delta)
	
	normal_move(direction_x, delta)
	
	animate_direction(Vector2(direction_x, direction_y))
	
	if Input.is_action_just_pressed("attack"): attack()
	
	move_and_slide()
