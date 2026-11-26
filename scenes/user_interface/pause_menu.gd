extends Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	# connect signal to GameManager
	var game_manager = get_tree().root.get_node_or_null("GameManager")
	if game_manager and game_manager.has_signal("toggle_game_paused"):
		game_manager.toggle_game_paused.connect(_on_game_manager_toggle_game_paused)
	elif get_parent() and get_parent().get_parent():
		get_parent().get_parent().toggle_game_paused.connect(_on_game_manager_toggle_game_paused)

func _on_game_manager_toggle_game_paused(is_paused: bool):
	if is_paused:
		show()
		$MarginContainer/VBoxContainer/ResumeButton.grab_focus()
	else:
		hide()

func _on_resume_button_pressed():
	var owner_node = owner if owner else $"../.."
	if "game_paused" in owner_node:
		owner_node.game_paused = false

func _input(event: InputEvent):
	if event.is_action_pressed("ui_home"):
		_on_resume_button_pressed()

func _on_main_menu_button_pressed():
	get_tree().paused = false  # reset pause state before changing scenes
	_reset_globals()
	get_tree().change_scene_to_file("res://scenes/user_interface/main_menu.tscn")

func _on_exit_game_button_pressed():
	get_tree().quit()

func _reset_globals():
	Globals.reset()