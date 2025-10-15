extends Node2D

@onready var tip_interact: Sprite2D = $"danilo_hometown/y-sorted-objects/player_mateo/tip_interact"
@onready var area_2d: Area2D = $Area2D
const A_5S_3 = preload("uid://dntq0tdotjt87")

var can_interact = true

var interacting_with = ""

func _ready() -> void:
	ObjectiveManager.add_objective(1, "Go to Danilo's Home")
	Hud.show_objectives()
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	area_2d.body_exited.connect(_on_area_2d_body_exited)

func _input(event: InputEvent) -> void:
	if event.is_action("interact"):
		if not can_interact:
			return
	
		if interacting_with == "danilo_door":
			can_interact = false
			DialogueManager.show_dialogue_balloon(A_5S_3, "katok")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "player_mateo":
		interacting_with = "danilo_door"
		tip_interact.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "player_mateo":
		interacting_with == "danilo_door"
		tip_interact.visible = false
		

func _to_danilo_house()->void:
	ObjectiveManager.complete_objective(1)
	SignalBus.next_scene.emit("res://scenes/game/act_5/scene_3/act_5_scene_3_bahay_ni_danilo.tscn")
