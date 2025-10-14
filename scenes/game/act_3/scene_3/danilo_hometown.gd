extends Node2D

@onready var player_danilo: CharacterBody2D = $player_danilo
const a3s3 = preload("res://dialogues/act_1/scene_2/a1s2.dialogue")

func _ready() -> void:
	ObjectiveManager.add_objective(1, "Exit the house")
	Hud.show_objectives()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_danilo.can_interact:
		DialogueManager.show_dialogue_balloon(a3s3, "start");


func bogok (res : String) -> void:
	print(res);
