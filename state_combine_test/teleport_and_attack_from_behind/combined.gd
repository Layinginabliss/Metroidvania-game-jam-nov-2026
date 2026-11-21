extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# try to mearge as posible ...

func _on_button_pressed() -> void: # test the this scene
	#print('button pressed ?')
	if $player_states/knock_back.run_this_current_state:
		var return_values =  $player_states/knock_back.end_state()
		$player_states/teleport.start_state(return_values)
		
		var return_values_e = $enemy_states/nock_back.end_state()
		$enemy_states/spawn_behind.start_state(return_values_e)

		
	elif $player_states/teleport.run_this_current_state:
		
		var return_values = $player_states/teleport.end_state()
		$player_states/knock_back.start_state(return_values)
		
		var return_values_e = $enemy_states/spawn_behind.end_state()
		$enemy_states/nock_back.start_state(return_values_e)
