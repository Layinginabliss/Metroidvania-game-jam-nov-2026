extends CharacterBody2D
# melee enemy that notices the player chases swings takes hits and dies

enum Facing { LEFT, RIGHT }
@export var initial_facing: Facing = Facing.LEFT

@export var hostile: bool = true
# seconds between swings
@export var melee_attack_cooldown: float = 1.0

const BASE_SPEED: float = 300.0
const HEALTH_BAR_TIME: float = 2.5
const KNOCKBACK: float = 300.0
const KNOCKBACK_TIME: float = 0.5

var health: int = 5
var max_health: int
var speed_multiplier: float = 1.0
var knockback_time: float = 0.0

var activated: bool = false
var is_alive: bool = true
var is_frozen: bool = false
var is_attacking:= false
var is_mid_attack: bool = false
var can_melee_attack: bool = true
var direction
var is_knockback := false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var _attack_id: int = 0
var _health_hide_timer: SceneTreeTimer
# side we get pushed to decided when we are hit
var _knockback_sign: float = 1.0

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var areas_root: Node2D = get_node_or_null("Areas")
@onready var notice_area: Area2D = get_node_or_null("Areas/NoticeArea")
@onready var attack_area: Area2D = get_node_or_null("Areas/AttackArea")
@onready var health_bar = get_node_or_null("HealthBar")
@onready var hurtbox: Area2D = get_node_or_null("Hurtbox")
@onready var hurtbox_shape = get_node_or_null("Hurtbox/CollisionShape2D")
@onready var death_sound = get_node_or_null("Sounds/DeathSound")
@onready var freeze_timer: Timer = get_node_or_null("Timers/FreezeTimer")
@onready var death_cleanup_timer: Timer = get_node_or_null("Timers/DeathCleanup")

signal died

func _ready() -> void:
	max_health = health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = false

	set_facing(initial_facing == Facing.RIGHT)
	_play("idle")


func _physics_process(delta: float) -> void:
	direction = Input.get_axis("left", "right")
	if not is_on_floor():
		velocity.y += gravity * delta

	knockback_time = maxf(knockback_time - delta, 0.0)

	var move_x := 0.0
	if is_alive and not is_frozen:
		move_x = _think()

	velocity.x = move_x + _knockback_x()
	move_and_slide()


# decides what to do this frame and returns the desired horizontal velocity
func _think() -> float:
	# notice the player
	if not activated and hostile and _player_in_notice_area():
		start_chase()

	if not activated:
		if not is_mid_attack:
			_play_idle()
		return 0.0

	# chase and attack
	var dist_x: float = Globals.player_pos.x - global_position.x
	set_facing(dist_x >= 0.0)

	if is_mid_attack:
		return 0.0

	if _hurtbox_in_attack_range():
		if can_melee_attack:
			_try_attack()
		# waiting for the cooldown
		if not is_mid_attack:
			_play("idle")
		return 0.0

	_play("charge")
	return signf(dist_x) * BASE_SPEED * speed_multiplier if absf(dist_x) > 5.0 else 0.0


# triggers chase animation
func start_chase() -> void:
	if not is_alive:
		return
	activated = true
	_play("charge")


# checks if player is in notice area and returns true or false
func _player_in_notice_area() -> bool:
	if notice_area == null:
		return false
	for body in notice_area.get_overlapping_bodies():
		if body.is_in_group("player") or body.name == "Player":
			return true
	for area in notice_area.get_overlapping_areas():
		if area.is_in_group("players_hurtboxes") or area.get_parent().is_in_group("player"):
			return true
	return false

# checks for player hurtbox and returns true or false
func _is_hurtbox(area: Area2D) -> bool:
	return area.is_in_group("players_hurtboxes")

func _hurtbox_in_attack_range() -> bool:
	if attack_area == null:
		return false
	for area in attack_area.get_overlapping_areas():
		if _is_hurtbox(area):
			return true
	return false


func _try_attack() -> void:
	is_mid_attack = true
	can_melee_attack = false
	var id := _attack_id

	var length := 0.5
	if anim.has_animation("attack"):
		anim.play("attack")
		length = anim.get_animation("attack").length

	# damage comes from the call method track in the attack animation
	await get_tree().create_timer(length).timeout
	if id != _attack_id:
		return
	_play_idle()

	# cooldown still locked in place then ready again
	await get_tree().create_timer(melee_attack_cooldown).timeout
	if id != _attack_id:
		return
	is_mid_attack = false
	can_melee_attack = true


# melee attack that deals the damage
# public so the attack animation can call it with a call method track
func attack() -> void:
	if attack_area == null:
		return

	for area in attack_area.get_overlapping_areas():
		if _is_hurtbox(area):
			var target = area if area.has_method("hit") else area.get_parent()
			if target.has_method("hit"):
				target.hit(global_position)
				return


# cancels any attack that is waiting on a timer and unlocks attacking
func _cancel_attack() -> void:
	_attack_id += 1
	is_mid_attack = false
	can_melee_attack = true


# taking damage and dying
# knockback only on the last combo hit or the killing hit
# source is true for a heavy hit from the player
func hit(source = false) -> void:
	if not is_alive:
		return

	var heavy: bool = source is bool and source

	# decide which way we get pushed from where the hit came from
	var dir := signf(global_position.x - Globals.player_pos.x)
	_knockback_sign = dir if dir != 0.0 else 1.0

	health -= 1
	_show_health_bar()
	_cancel_attack()

	activated = true
	hostile = true

	if heavy or health <= 0:
		knockback_time = KNOCKBACK_TIME

	is_frozen = true
	for t in [freeze_timer]:
		if t:
			t.start()

	_play("hit", true)

	if health <= 0:
		_die()


# called by the player on the last combo hit
func hit_heavy() -> void:
	hit(true)


func _die() -> void:
	is_alive = false
	activated = false
	if health_bar:
		health_bar.visible = false

	if hurtbox_shape:
		hurtbox_shape.set_deferred("disabled", true)
	_play("death", true)
	if death_sound:
		death_sound.play()
	sprite.modulate.a = 0.5
	if death_cleanup_timer:
		death_cleanup_timer.start()

	for group_name in get_groups():
		if group_name.begins_with("enemies_screen_"):
			remove_from_group(group_name)


func _show_health_bar() -> void:
	if not health_bar:
		return
	health_bar.value = health
	health_bar.visible = true

	# only the most recent hit timer can hide the bar
	var timer := get_tree().create_timer(HEALTH_BAR_TIME)
	_health_hide_timer = timer
	timer.timeout.connect(_hide_health_bar.bind(timer))


func _hide_health_bar(timer: SceneTreeTimer) -> void:
	if timer == _health_hide_timer and is_alive:
		health_bar.visible = false


# pushes away from the hit while knockback is running
func _knockback_x() -> float:
	if knockback_time <= 0.0:
		return 0.0
	return _knockback_sign * KNOCKBACK


# facing applied every frame on purpose so nothing else can
# leave the sprite and areas on the wrong side
func set_facing(face_right: bool) -> void:
	var side := 1.0 if face_right else -1.0
	sprite.flip_h = not face_right
	if areas_root:
		areas_root.scale.x = side

func _play(anim_name: StringName, restart: bool = false) -> void:
	if anim.has_animation(anim_name) and (restart or anim.current_animation != anim_name):
		anim.play(anim_name)

func _play_idle() -> void:
	_play("idle")

func set_frozen(state: bool) -> void:
	is_frozen = state
	if state:
		_cancel_attack()


# signal handlers
func _on_freeze_timer_timeout() -> void:
	# the next frame picks the right animation
	is_frozen = false

func _on_death_cleanup_timeout() -> void:
	queue_free()

func _on_hit_timer_timeout() -> void:
	pass
