extends Node2D

@onready var player_danilo: CharacterBody2D = $player_danilo
var A_1S_2: Resource

func _ready() -> void:
	FlashlightManager.set_current_scene("act_1", "scene_2")
	FlashlightManager.disable_flashlights()
	_load_dialogue()
	ObjectiveManager.add_objective(1, "Ride a Jeepney to Rizal Park")
	Hud.show_objectives()
	if BgmManager:
		BgmManager.stop_music();
		
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_1/scene_2/a1s2_en.dialogue"
	else:
		path = "res://dialogues/act_1/scene_2/a1s2.dialogue"
	
	A_1S_2 = load(path)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_danilo.can_interact:
		DialogueManager.show_dialogue_balloon(A_1S_2, "start");


func _on_area_2d_body_entered(body: Node2D) -> void:
	player_danilo.show_tip("jeep")
	SignalBus.in_jeep_area.emit()

func _on_area_2d_body_exited(body: Node2D) -> void:
	player_danilo.hide_tip("jeep")
	SignalBus.out_jeep_area.emit()

func bogok (res : String) -> void:
	print(res);
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
