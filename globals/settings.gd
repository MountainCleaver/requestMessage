extends Node

const SAVE_PATH := "user://settings.res"

var settings: SettingsResource;

func _ready() -> void:
	load_settings();
	apply_display_settings();
	

func load_settings() -> void:
	
	if FileAccess.file_exists(SAVE_PATH):
		settings = load(SAVE_PATH) as SettingsResource;
	else:
		settings = SettingsResource.new();
		save_settings();

func save_settings() -> void:
	var error := ResourceSaver.save(settings, SAVE_PATH);
	if error != OK:
		push_error("Failed to save settings: %s" % error);


func apply_display_settings() -> void:
	match settings.window_mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"windowed":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
