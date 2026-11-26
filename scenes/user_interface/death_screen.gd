extends Control


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$MarginContainer/VBoxContainer/RetryButton.grab_focus()


func _on_retry_button_pressed():
	get_tree().paused = false
	_reset_globals()
	get_tree().change_scene_to_file("res://scenes/levels/game_manager.tscn")


func _on_main_menu_button_pressed():
	get_tree().paused = false
	_reset_globals()
	get_tree().change_scene_to_file("res://scenes/user_interface/main_menu.tscn")


func _on_exit_game_button_pressed():
	get_tree().quit()


func _reset_globals():
	if Globals.has_method("reset"):
		Globals.reset()
	else:
		Globals.player_health = Globals.HEALTH_MAX
		Globals.player_control = true
		Globals.controls_hint_dismissed = false
		Globals.next_mode = ""
