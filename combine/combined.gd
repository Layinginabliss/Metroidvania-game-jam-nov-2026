extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# what to active what data to tranfer ??? hmm....


func _on_button_pressed() -> void: # test the this scene
	print('button pressed ?')
	if $knock_back/CharacterBody2D.run_this_current_state:
		var return_values =  $knock_back/CharacterBody2D.end_state()
		$spaw_behind/CharacterBody2D.start_state(return_values)
		
		# also change the enemy !!!!
		# here
		
	elif $spaw_behind/CharacterBody2D.run_this_current_state:
		var return_values = $spaw_behind/CharacterBody2D.end_state()
		$knock_back/CharacterBody2D.start_state(return_values)
