# act_5_scene_6.gd
extends Node2D

@onready var rain := $Rain
@onready var rain_splash := $Rain_splash
@onready var rain_sfx := $RAINSFX
@onready var danilo := $player_danilo

var dialogue_started := false
var A_5S_6: Resource

func _ready():
	start_cutscene()

func start_cutscene():
	if dialogue_started:
		return
	dialogue_started = true

	# Start rain and splash
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
	FlashlightManager.disable_flashlights() # force all flashlights OFF (fix for first-run leftovers)
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
			# Keep Danilo unable to move during this scene
			if danilo and danilo.has_method("set_can_move"):
				danilo.set_can_move(false)

			# Optional: stop rain if desired
			# if rain: rain.emitting = false
			# if rain_splash: rain_splash.emitting = false
			# if rain_sfx: rain_sfx.stop()

			# Transition to next scene
			act_5_scene_6_done()
		)

func act_5_scene_6_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_6"
	SaveManager.save_game()
	GameState.save_game()

	print("ACT 5 SCENE 6 DONE")

	# Emit signal to transition to the next scene
	SignalBus.act_num_scene_num_done.emit(
		"act_5",
		"scene_7",
		"res://scenes/game/act_5/scene_7/act_5_scene_7.tscn"
	)
