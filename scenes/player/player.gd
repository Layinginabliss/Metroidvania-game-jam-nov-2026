extends CharacterBody2D

var direction: float = 0.0
var is_healing: bool = false
var is_vulnerable: bool = true
var is_knockback: bool = false
var is_dead: bool = false

var facing_direction: String = "right"

var knockback_dir: Vector2 = Vector2.ZERO
var knockback_force: float = 0.0

# knockback
const KNOCKBACK_FORCE := 400.0

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


#attack component
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


# health component
func heal():
	if Globals.player_health < Globals.HEALTH_MAX:
		Globals.player_health += 1
		$Sounds/HealthSound.play()

func _on_vulnerable_timer_timeout():
	is_vulnerable = true
	_stop_hit_flicker()

func _on_knockback_timer_timeout():
	is_knockback = false
	knockback_force = 0.0
	knockback_dir = Vector2.ZERO
