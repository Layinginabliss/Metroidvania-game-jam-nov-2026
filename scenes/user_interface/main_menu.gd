extends Control

const SETTINGS_PATH := "user://settings.ini"
const GAME_SCENE := "res://scenes/levels/game_manager.tscn"

const ACTION_MAP := {
	"BtnLeft": "left",
	"BtnRight": "right",
	"BtnJump": "jump",
	"BtnAttack": "attack",
	"BtnInteract": "interact"
}

var selected_section: String = ""
var remap_action: String = ""
var remap_container_name: String = ""

var available_resolutions: Array[Vector2i] = []

# left side navigation buttons
@onready var btn_start: Button = $CanvasLayer/Margin/HBx/VBx/Panel/Margin/VBx/BtnStart
@onready var btn_settings: Button = $CanvasLayer/Margin/HBx/VBx/Panel/Margin/VBx/BtnSettings
@onready var btn_controls: Button = $CanvasLayer/Margin/HBx/VBx/Panel/Margin/VBx/BtnControls
@onready var btn_credits: Button = $CanvasLayer/Margin/HBx/VBx/Panel/Margin/VBx/BtnCredits
@onready var btn_exit: Button = $CanvasLayer/Margin/HBx/VBx/Panel/Margin/VBx/BtnExit

# right side panels
@onready var pnl_settings = $CanvasLayer/Margin/HBx/VBx2/PanelSettings
@onready var pnl_controls = $CanvasLayer/Margin/HBx/VBx2/PanelControls
@onready var pnl_credits = $CanvasLayer/Margin/HBx/VBx2/PanelCredits

# settings widgets
@onready var settings_box = $CanvasLayer/Margin/HBx/VBx2/PanelSettings/Margin/VBx
@onready var res_dropdown: OptionButton = $CanvasLayer/Margin/HBx/VBx2/PanelSettings/Margin/VBx/Resolution/OptionButton
@onready var fullscreen_check: CheckBox = $CanvasLayer/Margin/HBx/VBx2/PanelSettings/Margin/VBx/FullScr/CheckBox
@onready var borderless_check: CheckBox = $CanvasLayer/Margin/HBx/VBx2/PanelSettings/Margin/VBx/Borderless/CheckBox
@onready var sfx_slider: HSlider = $CanvasLayer/Margin/HBx/VBx2/PanelSettings/Margin/VBx/Sfx/Slider
@onready var bgm_slider: HSlider = $CanvasLayer/Margin/HBx/VBx2/PanelSettings/Margin/VBx/Bgm/Slider

# controls panel
@onready var controls_box = $CanvasLayer/Margin/HBx/VBx2/PanelControls/Margin/VBx

# key remap overlay
@onready var remap_overlay = $CanvasLayer/ControlRemap
@onready var remap_timer: Timer = $CanvasLayer/ControlRemap/TimerRemap
@onready var remap_label: Label = $CanvasLayer/ControlRemap/Panel/MarginContainer/Label
@onready var remap_button: Button = $CanvasLayer/ControlRemap/Button

var section_buttons: Dictionary = {}


func _ready() -> void:
	# saved settings (resolution, audio, controls) are applied by the
	# SettingsLoader autoload before any scene loads
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	section_buttons = {
		"settings": btn_settings,
		"controls": btn_controls,
		"credits": btn_credits,
	}

	# connect navigation buttons
	btn_start.pressed.connect(_on_start_pressed)
	btn_settings.pressed.connect(show_section.bind("settings"))
	btn_controls.pressed.connect(show_section.bind("controls"))
	btn_credits.pressed.connect(show_section.bind("credits"))
	btn_exit.pressed.connect(_on_exit_pressed)

	# setup resolutions
	setup_resolutions()

	# connect video and audio widgets
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	borderless_check.toggled.connect(_on_borderless_toggled)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	bgm_slider.value_changed.connect(_on_bgm_changed)

	# connect controls remap buttons
	setup_controls_remap_buttons()

	# hide all section panels on scene start
	hide_all_section_panels()
	# pnl_settings.show()
	# selected_section = "settings"

	# sync settings widgets with saved values
	load_settings()

	btn_start.grab_focus()


func hide_all_section_panels() -> void:
	pnl_settings.hide()
	pnl_controls.hide()
	pnl_credits.hide()


func show_section(section: String) -> void:
	hide_all_section_panels()
	selected_section = section
	match section:
		"settings":
			pnl_settings.show()
			fullscreen_check.grab_focus()
		"controls":
			pnl_controls.show()
			var first_btn = controls_box.get_node_or_null("BtnLeft/Btn")
			if first_btn:
				first_btn.grab_focus()
		"credits":
			# nothing focusable in the credits panel
			pnl_credits.show()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not remap_overlay.visible and remap_timer.time_left == 0.0:
		var section_btn = section_buttons.get(selected_section)
		if section_btn:
			hide_all_section_panels()
			section_btn.grab_focus()
		get_viewport().set_input_as_handled()


func setup_resolutions() -> void:
	available_resolutions = SettingsLoader.get_available_resolutions()
	var max_res = DisplayServer.screen_get_size()

	res_dropdown.clear()

	for res in available_resolutions:
		var label = "%dx%d" % [res.x, res.y]
		if res == max_res:
			label += " (Max)"
		res_dropdown.add_item(label)

	if not res_dropdown.item_selected.is_connected(_on_resolution_selected):
		res_dropdown.item_selected.connect(_on_resolution_selected)


func apply_resolution(index: int) -> void:
	if index < 0 or index >= available_resolutions.size():
		return

	var target_res = available_resolutions[index]

	if fullscreen_check.button_pressed:
		DisplayServer.window_set_size(target_res)
	else:
		SettingsLoader.apply_resolution(target_res)


func _on_resolution_selected(index: int) -> void:
	apply_resolution(index)
	save_setting("video", "resolution_index", index)


func _on_fullscreen_toggled(button_pressed: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)

	# lock the dropdown when in fullscreen
	res_dropdown.disabled = button_pressed

	if not button_pressed:
		apply_resolution(res_dropdown.selected)

	save_setting("video", "fullscreen_enabled", button_pressed)


func _on_borderless_toggled(button_pressed: bool) -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, button_pressed)
	save_setting("video", "borderless_enabled", button_pressed)


func _on_sfx_changed(value: float) -> void:
	var volume = value / 100.0
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume))
	save_setting("audio", "sfx", volume)


func _on_bgm_changed(value: float) -> void:
	var volume = value / 100.0
	var bus_idx = AudioServer.get_bus_index("BGM")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume))
	save_setting("audio", "bgm", volume)


func setup_controls_remap_buttons() -> void:
	for child_name in ACTION_MAP.keys():
		var action = ACTION_MAP[child_name]
		var row = controls_box.get_node_or_null(child_name)
		if row == null or not row.has_node("Btn"):
			push_warning("ACTION_MAP: no row named '%s' (with a 'Btn' child) in PanelControls/Margin/VBx" % child_name)
			continue
		if not InputMap.has_action(action):
			push_warning("ACTION_MAP: action '%s' (row '%s') does not exist in Project Settings > Input Map" % [action, child_name])
			continue
		var btn = row.get_node("Btn") as Button
		btn.pressed.connect(start_remap.bind(action, child_name))


func start_remap(action: String, container_name: String) -> void:
	if not remap_overlay.visible and remap_timer.time_left == 0:
		remap_action = action
		remap_container_name = container_name

		remap_label.text = "Press a new key for: " + container_name
		remap_overlay.show()
		remap_button.grab_focus()


func _input(event: InputEvent) -> void:
	if not remap_overlay.visible:
		return

	if event.is_pressed() and not event.is_echo():
		if event is InputEventKey and event.keycode == KEY_ESCAPE:
			hide_screen_remap()
			get_viewport().set_input_as_handled()
			return

		if event is InputEventKey:
			remap_timer.start()
			apply_key_remap(event)
			get_viewport().set_input_as_handled()


func apply_key_remap(event: InputEventKey) -> void:
	# update InputMap in memory
	for ev in InputMap.action_get_events(remap_action):
		if ev is InputEventKey:
			InputMap.action_erase_event(remap_action, ev)

	InputMap.action_add_event(remap_action, event)

	# save input action in settings.ini
	save_setting("controls", remap_action, event.keycode)

	# update button Text
	var btn = controls_box.get_node(remap_container_name + "/Btn") as Button
	if btn:
		btn.text = key_to_text(event)

	hide_screen_remap()


func hide_screen_remap() -> void:
	var btn = controls_box.get_node_or_null(remap_container_name + "/Btn")
	if btn:
		btn.grab_focus()
	remap_overlay.hide()


func update_control_button_labels() -> void:
	for child_name in ACTION_MAP.keys():
		var action = ACTION_MAP[child_name]
		var row = controls_box.get_node_or_null(child_name)
		if row and row.has_node("Btn") and InputMap.has_action(action):
			var btn = row.get_node("Btn") as Button
			btn.text = "None"
			for ev in InputMap.action_get_events(action):
				if ev is InputEventKey:
					btn.text = key_to_text(ev)
					break
				if ev is InputEventMouseButton and btn.text == "None":
					btn.text = mouse_to_text(ev)


func mouse_to_text(ev: InputEventMouseButton) -> String:
	match ev.button_index:
		MOUSE_BUTTON_LEFT: return "Mouse Left"
		MOUSE_BUTTON_RIGHT: return "Mouse Right"
		MOUSE_BUTTON_MIDDLE: return "Mouse Middle"
	return "Mouse %d" % ev.button_index


func key_to_text(ev: InputEventKey) -> String:
	var code: int = ev.keycode
	if code == 0:
		code = DisplayServer.keyboard_get_keycode_from_physical(ev.physical_keycode)
	return OS.get_keycode_string(code)


func save_setting(section: String, key: String, value: Variant) -> void:
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(section, key, value)
	config.save(SETTINGS_PATH)


# the SettingsLoader autoload already applied the saved video/audio/controls
# at boot this function only syncs the widgets with what was saved
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	if err != OK:
		update_control_button_labels()
		return

	var fs = config.get_value("video", "fullscreen_enabled", false)
	var bl = config.get_value("video", "borderless_enabled", false)
	var res_idx = config.get_value("video", "resolution_index", 0)

	fullscreen_check.set_pressed_no_signal(fs)
	borderless_check.set_pressed_no_signal(bl)

	# set_pressed_no_signal() doesn't emit "toggled" so sync the dropdown by hand
	res_dropdown.disabled = fs

	if res_idx >= 0 and res_idx < available_resolutions.size():
		res_dropdown.select(res_idx)

	var sfx_val = config.get_value("audio", "sfx", 1.0)
	var bgm_val = config.get_value("audio", "bgm", 1.0)

	sfx_slider.set_value_no_signal(sfx_val * 100.0)
	bgm_slider.set_value_no_signal(bgm_val * 100.0)

	update_control_button_labels()
