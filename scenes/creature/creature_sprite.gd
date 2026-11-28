extends AnimatedSprite2D

const FLICKER_MIN_ALPHA := 0.25
const FLICKER_STEP_TIME := 0.08

var flicker_tween: Tween = null

func _start_hit_flicker() -> void:
	_stop_hit_flicker()
	modulate.a = 1.0

	flicker_tween = create_tween().set_loops()
	flicker_tween.tween_property(self, "modulate:a", FLICKER_MIN_ALPHA, FLICKER_STEP_TIME)
	flicker_tween.tween_property(self, "modulate:a", 1.0, FLICKER_STEP_TIME)

func _stop_hit_flicker() -> void:
	if flicker_tween and flicker_tween.is_valid():
		flicker_tween.kill()
	flicker_tween = null
	modulate.a = 1.0
