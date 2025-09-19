extends Node

@onready var bgm: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready():
	if not bgm.get_parent():
		add_child(bgm)

		var music = preload("res://sound/soft-calm-piano-music-405074.mp3")

		# Enable looping
		if music is AudioStream:
			music.loop = true

		bgm.stream = music
		bgm.bus = "Master"   # Music will play on Master bus
		bgm.volume_db = -6   # Initial volume (a bit lower than default 0)
		bgm.play()

# 🎚 Music Volume Slider (Master bus)
func _on_music_slider_value_changed(value: float) -> void:
	# Convert 0.0 - 1.0 slider to decibels
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(value)
	)

# 🎚 SFX Volume Slider (SFX bus)
func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(value)
	)

# 🔇 Mute/Unmute Music (Master bus)
func _on_mute_button_pressed() -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	var muted = AudioServer.is_bus_mute(bus_idx)
	AudioServer.set_bus_mute(bus_idx, not muted)
