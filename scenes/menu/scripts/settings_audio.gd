extends Control

@onready var music_slider: HSlider = $VBoxContainer/MUSIC/music_slider
@onready var sfx_slider: HSlider = $VBoxContainer/SFX/sfx_slider
@onready var mute_check: CheckBox = $VBoxContainer/MUTE/mute_check


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_slider.value = Settings.settings.music_volume;
	sfx_slider.value = Settings.settings.sfx_volume;
	mute_check.button_pressed = Settings.settings.mute_all_sounds;
	
	music_slider.value_changed.connect(_on_music_slider_value_changed);
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed);
	mute_check.toggled.connect(_mute_toggled);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _mute_toggled(toggled: bool):
	if toggled:
		Settings.settings.mute_all_sounds = true;
		Settings.save_settings();
	else:
		Settings.settings.mute_all_sounds = false;
		Settings.save_settings();


func _on_music_slider_value_changed(value: float) -> void:
	Settings.settings.music_volume = value;
	Settings.save_settings();

func _on_sfx_slider_value_changed(value: float) -> void:
	Settings.settings.sfx_volume = value;
	Settings.save_settings();
