extends Node2D

signal screen_just_cleared

@export var night: bool = false

var player: Node2D = null

func _ready():
	# retrieve player dynamically using group membership
	player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		printerr("No Player found in group 'player'!")
		return

	var spawn_name = Globals.next_spawn_point
	var direction = Globals.next_facing_direction

	if has_node("SpawnPoints/" + spawn_name):
		var marker = get_node("SpawnPoints/" + spawn_name)
		player.global_position = marker.global_position
	else:
		print("spawn marker not found: '%s'. using player’s scene position." % spawn_name)

	# handle direction
	if direction == "left":
		player.facing_direction = "left"
		player.get_node("AnimatedSprite2D").flip_h = true
	elif direction == "right":
		player.facing_direction = "right"
		player.get_node("AnimatedSprite2D").flip_h = false
