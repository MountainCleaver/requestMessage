extends Node

const SAVE_PATH := "user://settings.res"

var settings: SettingsResource

func _ready() -> void:
	load_settings()
	apply_display_settings()
	apply_keybind_settings()
	#dito dapat ina apply yung audio settings
	
func load_settings() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		settings = load(SAVE_PATH) as SettingsResource
	else:
		settings = SettingsResource.new()
		save_settings()

func save_settings() -> void:
	var error := ResourceSaver.save(settings, SAVE_PATH)
	if error != OK:
		push_error("Failed to save settings: %s" % error)

func apply_display_settings() -> void:
	match settings.window_mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"windowed":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func apply_keybind_settings() -> void:
	if settings.key_bindings.is_empty():
		return
	
	for action_name in settings.key_bindings.keys():
		var ev_dict = settings.key_bindings[action_name]
		var ev = _event_from_dict(ev_dict)
		
		if ev:
			if InputMap.has_action(action_name):
				InputMap.action_erase_events(action_name)
				InputMap.action_add_event(action_name, ev)

func _event_from_dict(data: Dictionary) -> InputEvent:
	if data.get("type") == "key":
		var ev := InputEventKey.new()
		ev.physical_keycode = data.get("physical_keycode", 0)
		ev.unicode = data.get("unicode", 0)
		return ev
	return null

	
	# Apply global brightness
	BrightnessManager.set_brightness(settings.brightness)
