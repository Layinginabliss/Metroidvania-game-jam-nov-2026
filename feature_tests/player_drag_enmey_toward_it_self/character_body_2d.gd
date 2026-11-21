
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

@export var drag_force = 400

func check_draging_path_is_clear(enemy) -> bool:
	var head_ray = $check_if_the_path_is_clear/head_ray
	var tow_ray = $check_if_the_path_is_clear/tow_ray

	# Head ray
	head_ray.target_position = head_ray.to_local(enemy.head.global_position) # these ray set is kina
	head_ray.force_raycast_update()

	# Tow ray
	tow_ray.target_position = tow_ray.to_local(enemy.two.global_position)
	tow_ray.force_raycast_update()

	# Check collisions
	return not head_ray.is_colliding() and not tow_ray.is_colliding() # if collidng with body it's all fine

var being_dragged_enemy = null
var hodling_enmey_gravity = 0
var one_is_being_dragged = false
func _physics_process(delta):
	
	if Input.is_action_just_pressed("drag_enemy"):
		var closest_one = null
		var closest_distance = INF

		for enemy in enemys_in_range:
			var distance = global_position.distance_to(enemy.global_position)

			if distance < closest_distance:
				closest_distance = distance
				closest_one = enemy

		if closest_one != null and not one_is_being_dragged:
			var direction = closest_one.global_position.direction_to(global_position)
			
			# get hight box of enmey to set the path check
			
			#if check_draging_path_is_clear(closest_one):
			being_dragged_enemy = closest_one
			hodling_enmey_gravity = being_dragged_enemy.gravity
			being_dragged_enemy.gravity = 0.0
			closest_one.velocity = direction * drag_force # we need to drag whole body tward the player 
			$drag_enemy_for.start()
			one_is_being_dragged = true
			# TODO : turn off the gravity till it comes close enuft to to player
			# also check if the collition path is clear to drag not get stuck on everything

			$closest_one.text = closest_one.name
	
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

var enemys_in_range = []

func print_detected_enemys():
	$detected_enemys.text = ''
	for x in enemys_in_range:
		$detected_enemys.text += x.name + '\n'
		

func _on_drag_toward_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemy'):
		enemys_in_range.append(body)
		print_detected_enemys()
	pass # Replace with function body.


func _on_drag_toward_body_exited(body: Node2D) -> void:
	if body in enemys_in_range:
		enemys_in_range.erase(body)
		print_detected_enemys()

func _on_drag_enemy_for_timeout() -> void:
	being_dragged_enemy.velocity = Vector2.ZERO
	being_dragged_enemy.gravity = hodling_enmey_gravity
	one_is_being_dragged= false
	pass # Replace with function body.
