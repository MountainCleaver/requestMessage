extends Control

@onready var music_slider: HSlider = $VBoxContainer/MUSIC/music_slider
@onready var sfx_slider: HSlider = $VBoxContainer/SFX/sfx_slider
@onready var mute_check: CheckBox = $VBoxContainer/MUTE/mute_check

func _ready() -> void:
	# Load saved values (expect 0–100 since your sliders use that range)
	music_slider.value = Settings.settings.music_volume
	sfx_slider.value = Settings.settings.sfx_volume
	mute_check.button_pressed = Settings.settings.mute_all_sounds

	# Apply immediately
	_apply_music_volume(Settings.settings.music_volume)
	_apply_sfx_volume(Settings.settings.sfx_volume)
	_apply_mute(Settings.settings.mute_all_sounds)

	# Connect signals
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	mute_check.toggled.connect(_mute_toggled)

# === SIGNAL HANDLERS ===
func _on_music_slider_value_changed(value: float) -> void:
	Settings.settings.music_volume = value  # store as 0–100
	_apply_music_volume(value)
	Settings.save_settings()

func _on_sfx_slider_value_changed(value: float) -> void:
	Settings.settings.sfx_volume = value  # store as 0–100
	_apply_sfx_volume(value)
	Settings.save_settings()

func _mute_toggled(toggled: bool) -> void:
	Settings.settings.mute_all_sounds = toggled
	_apply_mute(toggled)
	Settings.save_settings()

# === HELPERS ===
func _apply_music_volume(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master") # Music = Master
	var normalized = value / 100.0  # convert 0–100 → 0.0–1.0
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(normalized))

func _apply_sfx_volume(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	var normalized = value / 100.0  # convert 0–100 → 0.0–1.0
	#AudioServer.set_bus_volume_db(bus_idx, linear_to_db(normalized))

func _apply_mute(state: bool) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_idx, state)
