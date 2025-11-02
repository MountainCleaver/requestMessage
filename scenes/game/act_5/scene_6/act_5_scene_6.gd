extends Node2D

@onready var rain := $Rain
@onready var rain_splash := $Rain_splash
@onready var rain_sfx := $RAINSFX
@onready var danilo := $player_danilo

var dialogue_started := false
var A_5S_6: Resource
var _scene_exiting := false  # <-- ADD THIS FLAG

func _ready():
	# Detect when player exits to main menu
	SignalBus.next_scene.connect(_on_scene_change)
	start_cutscene()

func _on_scene_change(path: String) -> void:
	# If going to main menu, mark as exiting
	if path == "res://scenes/menu/menu_main.tscn":
		_scene_exiting = true

func start_cutscene():
	if dialogue_started:
		return
	dialogue_started = true

	if rain:
		rain.emitting = true
	if rain_splash:
		rain_splash.emitting = true
	if rain_sfx:
		rain_sfx.play()

	if danilo and danilo.has_method("set_can_move"):
		danilo.set_can_move(false)

	_load_dialogue()

func _load_dialogue() -> void:
	FlashlightManager.set_current_scene("act_5", "scene_6")
	FlashlightManager.disable_flashlights()
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_5/scene_6/a5s6_en.dialogue"
	else:
		path = "res://dialogues/act_5/scene_6/a5s6.dialogue"

	A_5S_6 = load(path)
	var balloon = DialogueManager.show_dialogue_balloon(A_5S_6, "start", [self])
	if balloon:
		balloon.tree_exited.connect(func ():
			if _scene_exiting:
				print("Skipped save because exiting to main menu.")
				return

			if danilo and danilo.has_method("set_can_move"):
				danilo.set_can_move(false)

			act_5_scene_6_done()
		)

func act_5_scene_6_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_6"
	SaveManager.save_game()
	GameState.save_game()

	print("ACT 5 SCENE 6 DONE")

	SignalBus.act_num_scene_num_done.emit(
		"act_5",
		"scene_6",
		"res://scenes/game/act_5/scene_7/act_5_scene_7.tscn"
	)
