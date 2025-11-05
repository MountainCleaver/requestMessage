extends Node2D

@onready var player_danilo: CharacterBody2D = $player_danilo
@onready var buzz_audio: AudioStreamPlayer2D = $buzz_audio

var buzz_timer: Timer
var A_1S_4: Resource
var _in_reflection := false

func _ready() -> void:
	FlashlightManager.set_current_scene("act_1", "scene_4")
	FlashlightManager.disable_flashlights()
	_load_dialogue()
	if DialogueManager:
		DialogueManager.connect("dialogue_ended", Callable(self, "_on_dialogue_ended"))
		DialogueManager.show_dialogue_balloon(A_1S_4, "start")

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_1/scene_4/a1s4_en.dialogue"
	else:
		path = "res://dialogues/act_1/scene_4/a1s4.dialogue"

	A_1S_4 = load(path)

func _on_dialogue_ended(resource = null) -> void:
	if not _in_reflection:
		_in_reflection = true

		var choice = SaveManager.get_moral_choice("act_1_scene_3")
		if choice == "relief":
			DialogueManager.show_dialogue_balloon(A_1S_4, "option_relief")
		elif choice == "restless":
			DialogueManager.show_dialogue_balloon(A_1S_4, "option_restless")
		else:
			DialogueManager.show_dialogue_balloon(A_1S_4, "option_restless")

var in_bahay_area: bool = false

func _on_bahay_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		in_bahay_area = true 
		SignalBus.in_npc.emit("bahay")

func _on_bahay_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		in_bahay_area = false 
		SignalBus.out_npc.emit("bahay")
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
