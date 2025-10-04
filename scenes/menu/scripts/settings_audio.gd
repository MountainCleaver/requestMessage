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
	var bus_idx: int = AudioServer.get_bus_index("music") 
	if bus_idx == -1:
		push_warning("Music bus not found!")
		return

	var normalized: float = clamp(value / 100.0, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(normalized))


func _apply_sfx_volume(value: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index("sfx") 
	if bus_idx == -1:
		push_warning("SFX bus not found!")
		return

	var normalized: float = clamp(value / 100.0, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(normalized))


func _apply_mute(state: bool) -> void:
	# ✅ Mute both buses properly
	var master_idx: int = AudioServer.get_bus_index("Master")
	var music_idx: int = AudioServer.get_bus_index("music")
	var sfx_idx: int = AudioServer.get_bus_index("sfx")

	AudioServer.set_bus_mute(master_idx, state)
	AudioServer.set_bus_mute(music_idx, state)
	AudioServer.set_bus_mute(sfx_idx, state)
