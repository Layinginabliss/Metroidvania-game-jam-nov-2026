## The Player class handles everything related to the player character. It is not meant to be instantiated by itself and should omly be instantiated as it's own scene.
class_name Player extends Entity

@export var speed := 250.0
@export var jump_velocity := -400.0

@export var dash_speed := 1000.0
@export var dash_duration := 0.2

## Cooldown between attacks.
@export var attack_cooldown : float = 0.5
## Internal timer to track attack cooldown. Private member that should not be modified.
var _attack_timer : float = 100
## Where the player last looked at, both horizontally and vertically. Never 0 in x nor y.
var last_looked_at : Vector2i = Vector2i(1, 1)
## Where the player is currently looking at.
var direction : Vector2

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var jumps_left := 2
var is_dashing := false
var dash_timer := 0.0
var has_air_dashed := false


func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:

	# Reset abilities on ground
	if is_on_floor():
		jumps_left = 2
		has_air_dashed = false

	# Horizontal / vertical input
	var direction_x = Input.get_axis("left", "right")
	var direction_y = Input.get_axis("down", "up")
	direction = Vector2(direction_x, direction_y)
	if (direction_x != 0): last_looked_at.x = direction_x as int
	if (direction_y != 0): last_looked_at.y = direction_y as int

	# Jump / double jump
	if Input.is_action_just_pressed("ui_accept") and jumps_left > 0: _jump()
	
	_air_dash(delta)
	
	_normal_move(delta)
	
	if (attack_component): _attack_process(delta)
	
	move_and_slide()

func _attack_process(delta: float) -> void:
	# the direction changes together with the attack component's direction checks makes it so that
	# - while moving, vertical takes priority
	# - while standing still, horizontal takes priority
	var attack_direction : Vector2i = direction
	if (direction.x != 0 and direction.y != 0): attack_direction = Vector2i(0, direction.y as int)
	if (direction == Vector2.ZERO): attack_direction = last_looked_at
	attack_component.change_direction(attack_direction)
	
	if Input.is_action_just_pressed("attack") and _attack_timer > attack_cooldown:
		attack_component.attack()
		_attack_timer = 0.0
	
	if _attack_timer <= attack_cooldown:
		_attack_timer += delta

func _air_dash(delta: float) -> void:
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

func _normal_move(delta: float) -> void:
	# Gravity
	if not is_on_floor() and not is_dashing:
		velocity.y += gravity * delta
	
	# Horizontal movement
	if not is_dashing:
		velocity.x = direction.x * speed

func _jump() -> void:
	velocity.y = jump_velocity
	jumps_left -= 1
