
extends Area2D

var inside_bodies: Array[PhysicsBody2D] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$cool_down/attack_cool_down.timeout.connect(_on_attack_cool_down_timeout)


# Keep track of every physics body entering
func _on_body_entered(body: PhysicsBody2D) -> void: # TODO : we don't need this ?
	if not inside_bodies.has(body):
		inside_bodies.append(body)
		#print("Body entered: ", body.name)


# Remove bodies when they leave
func _on_body_exited(body: PhysicsBody2D) -> void:
	inside_bodies.erase(body)
	#print("Body exited: ", body.name)


# Find the closest body inside the Area2D
func get_closest_body() -> PhysicsBody2D:
	var closest_body: PhysicsBody2D = null
	var closest_distance: float = INF

	for body in inside_bodies:
		if not is_instance_valid(body):
			continue

		var distance = global_position.distance_to(body.global_position)

		if distance < closest_distance:
			closest_distance = distance
			closest_body = body

	return closest_body


# Cooldown timer finished
func _on_attack_cool_down_timeout() -> void:
	$cool_down.visible = false
