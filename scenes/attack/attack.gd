extends Node

@export var anim: AnimationPlayer



# restart true plays from the start even if already playing
func _play_anim(animation_name: String, restart: bool = false) -> void:
	if $AnimationPlayer.has_animation(animation_name):
		if restart:
			$AnimationPlayer.stop()
		$AnimationPlayer.play(animation_name)
