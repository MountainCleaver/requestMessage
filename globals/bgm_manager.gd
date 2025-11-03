extends Node

@onready var bgm: AudioStreamPlayer = AudioStreamPlayer.new()
const DEFAULT_MUSIC_PATH := "res://sound/soft-calm-piano-music-405074.mp3"
const RAIN_BGM_PATH := "res://sound/calming-rain-257596.mp3"

const MENU_SCENE_PATHS := [
	"res://scenes/menu/boot_warning.tscn",
	"res://scenes/menu/menu_create_acc_bday_gender.tscn",
	"res://scenes/menu/menu_create_acc_creds.tscn",
	"res://scenes/menu/menu_credits.tscn",
	"res://scenes/menu/menu_game_settings.tscn",
	"res://scenes/menu/menu_load_scenes.tscn",
	"res://scenes/menu/menu_login_acc.tscn",
	"res://scenes/menu/menu_report_a_bug.tscn",
	"res://scenes/menu/menu_new_game_slots.tscn",
	"res://scenes/menu/menu_load_game_slots.tscn",
	"res://scenes/menu/privacy_policy.tscn",
	"res://scenes/menu/menu_main.tscn"  # Added main menu
]

const RAIN_SCENE_PATHS := [
	"res://scenes/game/intro_scene.tscn",
	"res://scenes/game/act_1_title_scene.tscn",
	"res://scenes/game/act_1/scene_1/act_1_scene_1.tscn"
]

func _ready() -> void:
	# Critical: Process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if not bgm.get_parent():
		add_child(bgm)
	
	# Make sure BGM processes even when paused
	bgm.process_mode = Node.PROCESS_MODE_ALWAYS

	# Set default music
	var music := preload(DEFAULT_MUSIC_PATH)
	if music and music is AudioStream:
		bgm.stream = music
		bgm.bus = "music"
		bgm.volume_db = -10
		bgm.autoplay = false
		bgm.stream.loop = true  # Better way to set loop

	# Connect to scene changed signal
	get_tree().connect("scene_changed", Callable(self, "_on_scene_changed"))
	
	# Initial check with delay to ensure scene is loaded
	call_deferred("_check_current_scene")

func _check_current_scene() -> void:
	var current_scene := get_tree().current_scene
	if not current_scene:
		return

	var scene_path := current_scene.scene_file_path
	
	# Check for rain scenes first (more specific)
	for rain_path in RAIN_SCENE_PATHS:
		if scene_path == rain_path:
			_play_rain_music()
			return
	
	# Check for menu scenes
	for menu_path in MENU_SCENE_PATHS:
		if scene_path == menu_path:
			_play_menu_music()
			return
	
	# If not rain or menu scene, stop music
	bgm.stop()

func _play_rain_music() -> void:
	var rain_music := preload(RAIN_BGM_PATH)
	if rain_music and rain_music is AudioStream:
		# Only change stream if it's different
		if bgm.stream != rain_music:
			bgm.stream = rain_music
			bgm.bus = "music"
			bgm.volume_db = -20
			bgm.stream.loop = true
		
		if not bgm.playing:
			bgm.play()

func _play_menu_music() -> void:
	var menu_music := preload(DEFAULT_MUSIC_PATH)
	if menu_music and menu_music is AudioStream:
		# Only change stream if it's different
		if bgm.stream != menu_music:
			bgm.stream = menu_music
			bgm.bus = "music"
			bgm.volume_db = -20
			bgm.stream.loop = true
		
		if not bgm.playing:
			bgm.play()

func _on_scene_changed() -> void:
	# Wait for scene to fully load before checking
	call_deferred("_check_current_scene")

# --- Controls ---
func play_default_music() -> void:
	if not bgm.playing:
		bgm.play()

func play_music(path: String) -> void:
	if path != "":
		var music := load(path)
		if music and music is AudioStream:
			bgm.stream = music
			bgm.stream.loop = true
			bgm.play()

func stop_music() -> void:
	if bgm.playing:
		bgm.stop()

func pause_music() -> void:
	if bgm.playing:
		bgm.stream_paused = true

func resume_music() -> void:
	if bgm.stream_paused:
		bgm.stream_paused = false
