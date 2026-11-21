extends Node2D

@export var attack_to: Node2D


func _process(delta: float) -> void:
	if attack_to != null:
		$spear.look_at(attack_to.global_position)


func _on_cool_down_timer_timeout() -> void:
	if attack_to == null:
		return

	var ray: RayCast2D = $spear/RayCast2D

	ray.force_raycast_update()

	# Only fire if the ray hits the player
	if not ray.is_colliding():
		return

	if not ray.get_collider().is_in_group('player'):
		return

	var k = $spear.duplicate()
	$traviling_projectlies.add_child(k)

	k.global_transform = $spear.global_transform
	k.call_despawn()
	k.go = true
