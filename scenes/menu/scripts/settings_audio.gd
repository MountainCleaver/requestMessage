extends Control

@onready var music_slider: HSlider = $VBoxContainer/MUSIC/music_slider
@onready var sfx_slider: HSlider = $VBoxContainer/SFX/sfx_slider
@onready var mute_check: CheckBox = $VBoxContainer/MUTE/mute_check


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_slider.value = Settings.music_volume;
	sfx_slider.value = Settings.sfx_volume;
	mute_check.button_pressed = Settings.mute_all_sounds;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
