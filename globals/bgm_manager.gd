extends Node

@onready var bgm: AudioStreamPlayer = AudioStreamPlayer.new()
const DEFAULT_MUSIC_PATH := "res://sound/soft-calm-piano-music-405074.mp3"

func _ready():
	if not bgm.get_parent():
		add_child(bgm)
	play_default_music()

# 🔊 Play the default menu music
func play_default_music() -> void:
	var music = preload("res://sound/soft-calm-piano-music-405074.mp3")
	if music and music is AudioStream:
		music.loop = true
		bgm.stream = music
	bgm.bus = "Master"   # Play on Master bus
	bgm.volume_db = -6   # Slightly lower than 0 dB
	bgm.play()

# 🔊 Play a different track (for in-game, cutscenes, etc.)
func play_music(path: String = "") -> void:
	if path != "":
		var music = load(path)  # ✅ use load() for variable paths
		if music and music is AudioStream:
			music.loop = true
			bgm.stream = music
	bgm.play()

# ⏹ Stop music
func stop_music() -> void:
	if bgm.playing:
		bgm.stop()

# ⏸ Pause music
func pause_music() -> void:
	if bgm.playing:
		bgm.stream_paused = true

# ▶ Resume music
func resume_music() -> void:
	if bgm.stream_paused:
		bgm.stream_paused = false

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
