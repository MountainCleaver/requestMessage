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
	"res://scenes/menu/privacy_policy.tscn"
]

const MENU_SCENE_NAMES := [
	"boot_warning",
	"menu_create_acc_bday_gender",
	"menu_create_acc_creds",
	"menu_credits",
	"menu_game_settings",
	"menu_load_scenes",
	"menu_login_acc",
	"menu_report_a_bug"
]

const RAIN_SCENE_PATHS := [
	"res://scenes/game/intro_scene.tscn",
	"res://scenes/game/act_1_title_scene.tscn",
	"res://scenes/game/act_1/scene_1/act_1_scene_1.tscn"
]

const RAIN_SCENES := [
	"intro_scene",
	"act_1_title_scene",
	"act_1_scene_1"
]

func _ready() -> void:
	if not bgm.get_parent():
		add_child(bgm)

	var music := preload(DEFAULT_MUSIC_PATH)
	if music and music is AudioStream:
		bgm.stream = music
		bgm.bus = "music"
		bgm.volume_db = -20
		bgm.autoplay = false
		if bgm.stream.has_method("set_loop"):
			bgm.stream.set_loop(true)

	get_tree().connect("scene_changed", Callable(self, "_on_scene_changed"))
	_check_current_scene()

func _check_current_scene() -> void:
	var current_scene := get_tree().current_scene
	if not current_scene:
		return

	var scene_name := current_scene.name  # use the node name instead of filename

	# --- RAIN BGM for game scenes ---
	if scene_name in RAIN_SCENES:
		if bgm.stream != preload(RAIN_BGM_PATH):
			bgm.stream = preload(RAIN_BGM_PATH)
			bgm.bus = "music"
			bgm.volume_db = -20
			if bgm.stream.has_method("set_loop"):
				bgm.stream.set_loop(true)
		if not bgm.playing:
			bgm.play()
		return  # skip normal menu checks

	# --- Original menu music logic ---
	if scene_name in MENU_SCENE_NAMES:
		if not bgm.playing:
			bgm.play()
	else:
		bgm.stop()



func _on_scene_changed(_new_scene: Node) -> void:
	_check_current_scene()

# --- Controls ---
func play_default_music() -> void:
	if not bgm.playing:
		bgm.play()

func play_music(path: String) -> void:
	if path != "":
		var music := load(path)
		if music and music is AudioStream:
			bgm.stream = music
			if bgm.stream.has_method("set_loop"):
				bgm.stream.set_loop(true)
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
