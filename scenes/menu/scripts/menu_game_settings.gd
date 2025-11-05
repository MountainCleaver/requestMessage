extends Control

@onready var v_box_container: VBoxContainer = $options_label/VBoxContainer
@onready var setting_container: Panel = $setting_container

@onready var option_audio: Button = $options_label/VBoxContainer/option_audio
@onready var option_display: Button = $options_label/VBoxContainer/option_display
@onready var option_controls: Button = $options_label/VBoxContainer/option_controls

@onready var exit: Button = $exit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var options_settings := v_box_container.get_children();
	options_settings[0].grab_focus();
	
	var audio_settings := load("res://scenes/menu/settings_audio.tscn");
	var audio_settings_instance = audio_settings.instantiate();
	setting_container.add_child(audio_settings_instance);

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("escape"):
		#_on_exit_pressed();


func _on_option_audio_pressed() -> void:
	_setting_switcher("res://scenes/menu/settings_audio.tscn")

func _on_option_display_pressed() -> void:
	_setting_switcher("res://scenes/menu/settings_display.tscn");

func _on_option_controls_pressed() -> void:
	_setting_switcher("res://scenes/menu/settings_controls.tscn")

func _on_option_language_pressed() -> void:
	_setting_switcher("res://scenes/menu/settings_language.tscn")

func _setting_switcher(path: String):
	for child in setting_container.get_children():
		child.queue_free()
		
	var settings := load(path);
	var settings_instance = settings.instantiate();
	
	setting_container.add_child(settings_instance);
		

func _on_exit_pressed() -> void:
	queue_free();
	SignalBus.exit_overlay.emit();

func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
