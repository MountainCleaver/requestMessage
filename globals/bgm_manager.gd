extends Node

@onready var bgm: AudioStreamPlayer = AudioStreamPlayer.new()
const DEFAULT_MUSIC_PATH := "res://sound/soft-calm-piano-music-405074.mp3"

# List of menu scenes where the music should play
var menu_scenes := [
	"res://scenes/menu/boot_warning.tscn",
	"res://scenes/menu/menu_create_acc_bday_gender.tscn",
	"res://scenes/menu/menu_create_acc_creds.tscn",
	"res://scenes/menu/menu_credits.tscn",
	"res://scenes/menu/menu_game_settings.tscn",
	"res://scenes/menu/menu_load_scenes.tscn",
	"res://scenes/menu/menu_login_acc.tscn",
	"res://scenes/menu/menu_report_a_bug.tscn"
]

func _ready():
	if not bgm.get_parent():
		add_child(bgm)

	var music = preload(DEFAULT_MUSIC_PATH)
	if music and music is AudioStream:
		bgm.stream = music

	bgm.bus = "Master"
	bgm.volume_db = -6

	get_tree().connect("scene_changed", Callable(self, "_on_scene_changed"))

	# Start music only if first scene is menu scene
	_check_current_scene()

func _check_current_scene():
	var scene_name := get_tree().current_scene.name
	if scene_name in menu_scene_names:
		if not bgm.playing:
			bgm.play()
	else:
		bgm.stop()

var menu_scene_names := [
	"boot_warning",
	"menu_create_acc_bday_gender",
	"menu_create_acc_creds",
	"menu_credits",
	"menu_game_settings",
	"menu_load_scenes",
	"menu_login_acc",
	"menu_report_a_bug"
]

func _on_music_finished():
	bgm.play()

func _on_scene_changed(new_scene: Node) -> void:
	_check_current_scene()


# 🔊 Play the default menu music
func play_default_music() -> void:
	if not bgm.playing:
		bgm.play()

# 🔊 Play a different track
func play_music(path: String) -> void:
	if path != "":
		var music = load(path)
		if music and music is AudioStream:
			bgm.stream = music
			bgm.loop = true
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

# 🔇 Mute/Unmute Music
func _on_mute_button_pressed() -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	var muted = AudioServer.is_bus_mute(bus_idx)
	AudioServer.set_bus_mute(bus_idx, not muted)
