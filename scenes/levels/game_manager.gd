extends Node

signal toggle_game_paused(is_paused: bool)

# Name of the action in Project Settings > Input Map that interacts / picks things up.
# Change this if your action is called something else.
const INTERACT_ACTION := "interact"

var current_intro_screen: int = 1

var current_mission = Globals.current_area

var current_level_scene: Node = null

var fade_rect: ColorRect

# the "press [E]" prompt (a small panel with a label inside it)
@onready var interact_prompt: PanelContainer = $CanvasLayer/InteractPrompt
@onready var interact_key_label: Label = $CanvasLayer/InteractPrompt/KeyLabel

# where in the world the prompt should be drawn (it follows this point while visible)
var _interact_world_pos: Vector2 = Vector2.ZERO

# auto-changes the pause state then signals PauseMenu the pause state
var game_paused: bool = false:
	set(value):
		game_paused = value
		get_tree().paused = game_paused
		if game_paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			# $Music.stream_paused = true

		if not game_paused:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			# $Music.stream_paused = false

		emit_signal("toggle_game_paused", game_paused)


func _ready():
	# lets items / NPCs find the game manager with get_tree().get_first_node_in_group("game_manager")
	add_to_group("game_manager")

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game_paused = false
	Globals.player_control = true

	interact_prompt.visible = false

	start_new_game()

	Globals.connect("stat_change", update_health_text)

	$CanvasLayer/Control/HUD/HealthBar/HealthHi.visible = true

	# creating fade screen with code
	var fade_layer = CanvasLayer.new()
	fade_layer.layer = 128 # or any higher value to make sure it renders on top of all other HUDs/Menus
	add_child(fade_layer)

	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0) # starts fully transparent
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT) # covers the whole screen
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # to not block clicks
	fade_layer.add_child(fade_rect)


func _process(_delta):
	# keeps the prompt glued to the item while the camera moves
	if interact_prompt.visible:
		_place_interact_prompt()


func _physics_process(_delta):
	if Globals.player_health <= 0:
		get_tree().change_scene_to_file("res://scenes/user_interface/death_screen.tscn")


func _input(event):
	# to block UI interactions during level transitions
	if not Globals.player_control:
		return

	var pause_menu = $CanvasLayer/PauseMenu

	if event.is_action_pressed("ui_cancel"):
		if pause_menu.visible:
			game_paused = false  # unpause
			pause_menu.visible = false  # hide Pause Menu

		else:
			game_paused = not game_paused


func update_health_text():
	$CanvasLayer/Control/HUD/HealthBar/VBoxContainer/ProgressBar.value = Globals.player_health


func start_new_game():

	# we make sure to reset all flags and variables first befoure a fresh new game like health..etc
	Globals.reset()

	# now we load/instantiate the level inside game manager as a child node
	load_level("room_01")


func load_level(level_name: String, spawn_point: String = "Default", facing_direction: String = "right"):

	# don't leave a prompt hanging around from the previous level
	hide_interact_prompt()

	Globals.current_area = level_name
	Globals.next_spawn_point = spawn_point
	Globals.next_facing_direction = facing_direction

	# fade out start
	Globals.player_control = false # stop player movement during transition
	if fade_rect:
		var tween = create_tween()
		tween.tween_property(fade_rect, "color:a", 1.0, 0.8) # fade to black over 0.8 seconds
		await tween.finished
	# fade out end

	await unload_level()  # wait until level is freed

	level_name = level_name.to_lower()

	var path = "res://scenes/levels/%s.tscn" % level_name
	var level_scene = load(path).instantiate()

	# it is important to name all levels nodes exactly "Level" cause some nodes access the level by this exact name
	level_scene.name = "Level"
	add_child(level_scene)
	current_level_scene = level_scene

	# fade in start
	if fade_rect:
		var tween = create_tween()
		tween.tween_property(fade_rect, "color:a", 0.0, 0.8) # fade to transparent over 0.8 seconds
		await tween.finished

	Globals.player_control = true # give control back to player
	# fade in end

func unload_level():
	if current_level_scene and current_level_scene.is_inside_tree():
		current_level_scene.queue_free()
		await get_tree().process_frame
		current_level_scene = null


# ---------------------------------------------------------------------------
# Interact prompt: shows the key currently bound to an Input Map action
# ---------------------------------------------------------------------------

# world_pos = where the prompt should appear IN THE WORLD (e.g. the item's global_position
# plus a small offset upward). It is converted to screen position for you.
func show_interact_prompt(world_pos: Vector2, action: String = INTERACT_ACTION) -> void:
	_interact_world_pos = world_pos

	var key_text := get_action_key_text(action)
	if interact_key_label.text != key_text:
		interact_key_label.text = key_text
		interact_prompt.reset_size()  # shrink/grow the panel to fit the new text

	interact_prompt.visible = true
	_place_interact_prompt()


func hide_interact_prompt() -> void:
	interact_prompt.visible = false


func _place_interact_prompt() -> void:
	var screen_pos := world_to_canvas_position(_interact_world_pos)
	interact_prompt.global_position = screen_pos - interact_prompt.size / 2.0  # centered on the point


# Returns the text of the first key bound to the action, e.g. "E" or "Space".
# Reads the InputMap live, so it stays correct if you add key rebinding later.
func get_action_key_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"

	var events := InputMap.action_get_events(action)

	# prefer a keyboard key
	for event in events:
		if event is InputEventKey:
			if event.physical_keycode != KEY_NONE:
				return OS.get_keycode_string(event.get_physical_keycode_with_modifiers())
			return OS.get_keycode_string(event.get_keycode_with_modifiers())

	# otherwise fall back to whatever is bound (mouse button, gamepad button...)
	if events.size() > 0:
		return events[0].as_text()

	return "?"


func world_to_canvas_position(world_pos: Vector2) -> Vector2:
	var vp = get_viewport()
	var canv_tf = vp.get_canvas_transform()
	return canv_tf * world_pos
