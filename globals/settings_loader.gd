extends Node

const SETTINGS_PATH := "user://settings.ini"
const RESOLUTION_PRESETS := [
	Vector2i(800, 600),
	Vector2i(1280, 720),
	Vector2i(1440, 900),
	Vector2i(1920, 1080)
]


func _ready() -> void:
	apply_saved_settings()


# single source of truth for the resolution list so the index saved in
# settings always points at the same resolution when loaded at boot
func get_available_resolutions() -> Array[Vector2i]:
	var max_res := DisplayServer.screen_get_size()
	var result: Array[Vector2i] = []
	for res in RESOLUTION_PRESETS:
		if res.x <= max_res.x and res.y <= max_res.y:
			result.append(res)
	if not result.has(max_res):
		result.append(max_res)
	return result


# resize the window and center it on the current screen (windowed mode only)
func apply_resolution(target_res: Vector2i) -> void:
	DisplayServer.window_set_size(target_res)
	var current_screen = DisplayServer.window_get_current_screen()
	var screen_rect = DisplayServer.screen_get_usable_rect(current_screen)
	var new_pos = screen_rect.position + (screen_rect.size - target_res) / 2
	# keep the title bar from getting stuck under the top edge of the screen
	if new_pos.y < 30:
		new_pos.y = 30
	DisplayServer.window_set_position(new_pos)


func apply_saved_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	# Video
	var fs = config.get_value("video", "fullscreen_enabled", false)
	var bl = config.get_value("video", "borderless_enabled", false)
	var res_idx = config.get_value("video", "resolution_index", 0)

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fs else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, bl)

	if not fs:
		var resolutions := get_available_resolutions()
		if res_idx >= 0 and res_idx < resolutions.size():
			apply_resolution(resolutions[res_idx])

	# Audio
	var sfx_val = config.get_value("audio", "sfx", 1.0)
	var bgm_val = config.get_value("audio", "bgm", 1.0)
	var sfx_bus = AudioServer.get_bus_index("SFX")
	var bgm_bus = AudioServer.get_bus_index("BGM")
	if sfx_bus != -1: AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_val))
	if bgm_bus != -1: AudioServer.set_bus_volume_db(bgm_bus, linear_to_db(bgm_val))

	# Controls
	if config.has_section("controls"):
		for action in config.get_section_keys("controls"):
			var keycode = config.get_value("controls", action, 0)
			if keycode > 0 and InputMap.has_action(action):
				for ev in InputMap.action_get_events(action):
					if ev is InputEventKey:
						InputMap.action_erase_event(action, ev)
				var new_ev = InputEventKey.new()
				new_ev.keycode = keycode
				InputMap.action_add_event(action, new_ev)
