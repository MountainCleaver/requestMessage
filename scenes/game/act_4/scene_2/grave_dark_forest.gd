extends Node2D

# === PRELOADS ===
const A_4S_2 = preload("res://dialogues/act_4/a4s2.dialogue")
const GRAVEYARD = preload("res://scenes/game/act_4/scene_2/graveyard.tscn")

@onready var player_danilo: CharacterBody2D = $"y-sorted/player_danilo"
@onready var entrance: Area2D = $"entrance"
@onready var signage: Area2D = $"y-sorted/decorations/signage"
@onready var tip: Sprite2D = $"y-sorted/player_danilo/tip_interact"
@onready var flashlight: PointLight2D = $"y-sorted/player_danilo/PointLight2D2"

var dialogue_shown: bool = false

func _on_ready() -> void:
	tip.visible = false
	signage.body_entered.connect(_on_signage_body_entered)
	signage.body_exited.connect(_on_signage_body_exited)
	player_danilo.can_move = false
	await get_tree().create_timer(1.0).timeout
	DialogueManager.show_dialogue_balloon(A_4S_2, "start");
	player_danilo.can_move = true


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
		
	if player_danilo.can_interact and player_danilo.current_npc == "signage":
		player_danilo.last_direction = Vector2.UP
		Hud.add_popup_image("res://assets/HUD/signage_darkforest.png")
		Hud._toggle_popup()
		player_danilo.force_cannot_move = Hud.popup_showing
		print("Signage interacted — HUD shown")

		if not dialogue_shown:
			dialogue_shown = true
			await get_tree().create_timer(0.5).timeout 
			DialogueManager.show_dialogue_balloon(A_4S_2, "signage")
		

func _on_signage_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	player_danilo.can_interact = true
	player_danilo.current_npc = "signage"
	tip.visible = true  # show interact tip


func _on_signage_body_exited(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	player_danilo.can_interact = false
	player_danilo.current_npc = ""
	tip.visible = false  # hide interact tip

func _on_entrance_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return

	print("Player entered entrance — loading graveyard...")
	ObjectiveManager.complete_objective(1)
	Hud.hide_objectives()
	_transition_to_graveyard()

func _transition_to_graveyard() -> void:
	TransitionFade.transition();
	player_danilo.can_move = false
	await get_tree().create_timer(3,0).timeout 
	get_tree().change_scene_to_packed(GRAVEYARD)
		
