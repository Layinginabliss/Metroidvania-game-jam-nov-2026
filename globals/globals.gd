extends Node

# signal to GameManager to tell it to update the UI
signal stat_change

# player status
var player_control: bool = false
var player_pos: Vector2

var current_area := "room_01"
var next_spawn_point: String = "default"
var next_facing_direction: String = "right"  # or "left"

const HEALTH_MAX: int = 5
var player_health: int = 5:
	set(value):
		player_health = value
		stat_change.emit()

# condition flags
# var controls_hint_dismissed: bool = false

func reset():
	player_control = false
	current_area = "room_01"
	next_spawn_point = "default"
	next_facing_direction = "right"
	player_health = HEALTH_MAX
	
	# condition flags
	# controls_hint_dismissed = false
	
