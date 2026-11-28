extends CharacterBody2D

var direction: float = 0.0
var is_healing: bool = false
var is_vulnerable: bool = true
var is_knockback: bool = false
var is_dead: bool = false
var is_attacking: bool = false

var facing_direction: String = "right"

var knockback_dir: Vector2 = Vector2.ZERO
var knockback_force: float = 0.0

# knockback
const KNOCKBACK_FORCE := 400.0

# melee combo
const COMBO_COUNT := 2

var combo_stage: int = 0
var combo_queued: bool = false

var flicker_tween: Tween = null
const FLICKER_MIN_ALPHA := 0.25
const FLICKER_STEP_TIME := 0.08

signal died

func _ready():
	add_to_group("player")

func _physics_process(_delta):

	if Globals.player_control:
		direction = Input.get_axis("left", "right")
		
		# flip facing direction but not in the middle of an attack
		if not is_attacking:
			if Input.is_action_pressed("right") and facing_direction != "right":
				facing_direction = "right"
				$AnimatedSprite2D.flip_h = false
				$AttackArea.scale.x = 1.0

			if Input.is_action_pressed("left") and facing_direction != "left":
				facing_direction = "left"
				$AnimatedSprite2D.flip_h = true
				$AttackArea.scale.x = -1.0


	# attack input first press starts the combo next presses queue the next hit
	# NOTE may remove attacking
	if Input.is_action_just_pressed("attack") and is_on_floor() and Globals.player_control and not is_knockback:
		if not is_attacking:
			_start_attack(1)
		elif combo_stage < COMBO_COUNT:
			combo_queued = true


	# play appropriate animations
	# skipped while knocked back or attacking
	if not is_knockback and not is_attacking:
		if not is_on_floor():
			if velocity.y < 0:
				if $AnimationPlayer.current_animation != "jump":
					_play_anim("jump")
			else:
				if $AnimationPlayer.current_animation != "fall":
					_play_anim("fall")
		else:
			if direction != 0:
				if $AnimationPlayer.current_animation != "run":
					_play_anim("run")
			else:
				if $AnimationPlayer.current_animation != "idle":
					_play_anim("idle")


func _start_attack(stage: int) -> void:
	is_attacking = true
	combo_stage = stage
	_play_anim("attack_%d" % stage, true)


# deals the damage
func attack() -> void:
	var already_hit := []
	for area in $AttackArea.get_overlapping_areas():
		if not area.is_in_group("enemy_hurtboxes"):
			continue
		var target = area if area.has_method("hit") else area.get_parent()
		if target.has_method("hit") and not already_hit.has(target):
			already_hit.append(target)
			# last combo hit pushes the enemy back
			if combo_stage >= COMBO_COUNT and target.has_method("hit_heavy"):
				target.hit_heavy()
			else:
				target.hit()

# ends the combo and cancels a hit that is still waiting on its timer
func _stop_attack() -> void:
	is_attacking = false
	combo_stage = 0
	combo_queued = false

func hit(_enemy_position):
	if is_vulnerable:
		is_vulnerable = false

		# last hit death hit
		if Globals.player_health <= 1:
			is_dead = true
			died.emit()
			is_knockback = false
			velocity = Vector2.ZERO
			_stop_attack()
			_stop_hit_flicker()

			$Sounds/HitSound.play()

			# play death animation and wait for it
			var death_length := 1.0
			if $AnimationPlayer.has_animation("death"):
				_play_anim("death", true)
				death_length = $AnimationPlayer.get_animation("death").length
			await get_tree().create_timer(death_length).timeout

			Globals.player_health -= 1

		# normal hit
		else:
			_stop_attack()
			is_knockback = true
			knockback_dir = (global_position - _enemy_position).normalized()
			if knockback_dir == Vector2.ZERO:
				knockback_dir = Vector2.LEFT if facing_direction == "right" else Vector2.RIGHT
			knockback_force = KNOCKBACK_FORCE

			$Timers/VulnerableTimer.start()
			$Timers/KnockbackTimer.start()
			$Sounds/HitSound.play()

			_play_anim("hurt", true)
			_start_hit_flicker()

			Globals.player_health -= 1

# restart true plays from the start even if already playing
func _play_anim(animation_name: String, restart: bool = false) -> void:
	if $AnimationPlayer.has_animation(animation_name):
		if restart:
			$AnimationPlayer.stop()
		$AnimationPlayer.play(animation_name)

func heal():
	if Globals.player_health < Globals.HEALTH_MAX:
		Globals.player_health += 1
		$Sounds/HealthSound.play()

func _start_hit_flicker() -> void:
	_stop_hit_flicker()
	$AnimatedSprite2D.modulate.a = 1.0

	flicker_tween = create_tween().set_loops()
	flicker_tween.tween_property($AnimatedSprite2D, "modulate:a", FLICKER_MIN_ALPHA, FLICKER_STEP_TIME)
	flicker_tween.tween_property($AnimatedSprite2D, "modulate:a", 1.0, FLICKER_STEP_TIME)

func _stop_hit_flicker() -> void:
	if flicker_tween and flicker_tween.is_valid():
		flicker_tween.kill()
	flicker_tween = null
	$AnimatedSprite2D.modulate.a = 1.0


func _on_animation_player_animation_finished(anim_name):
	if anim_name.begins_with("jump"):
		if is_on_floor():
			_play_anim("idle")
	elif anim_name.begins_with("attack"):
		if combo_queued and combo_stage < COMBO_COUNT:
			combo_queued = false
			_start_attack(combo_stage + 1)
		else:
			_stop_attack()

func _on_vulnerable_timer_timeout():
	is_vulnerable = true
	_stop_hit_flicker()

func _on_knockback_timer_timeout():
	is_knockback = false
	knockback_force = 0.0
	knockback_dir = Vector2.ZERO
