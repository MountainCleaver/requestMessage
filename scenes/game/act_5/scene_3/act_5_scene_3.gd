extends Node2D

# === PRELOADS ===
const a5s3 = preload("res://dialogues/act_5/scene 3/a5s3.dialogue")
const danilo_hometown = preload("res://scenes/game/act_5/scene_3/danilo_hometown.tscn")
const danilo_hometown_house = preload("res://scenes/game/act_5/scene_3/danilo_hometown_house.tscn")

@onready var area_2d: Area2D = $"danilo_hometown/y-sorted-objects/door/Area2D"
@onready var wendy: CharacterBody2D = $"danilo_hometown/y-sorted-objects/wendy"
@onready var npc_mira: CharacterBody2D = $"danilo_hometown/y-sorted-objects/npc_mira"
@onready var npc_danilo: CharacterBody2D = $"danilo_hometown/y-sorted-objects/npc_danilo"
@onready var player_mateo: CharacterBody2D = $"danilo_hometown/y-sorted-objects/player_mateo"
@onready var tip_interact: Sprite2D = $"danilo_hometown/y-sorted-objects/player_mateo/tip_interact"

var can_interact: bool = false

func _ready() -> void:
	tip_interact.visible = false  # nakatago muna
	DialogueManager.dialogue_started.connect(_on_dialogue_start)
	DialogueManager.dialogue_ended.connect(_on_dialogue_finish)
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	area_2d.body_exited.connect(_on_area_2d_body_exited)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_interact:
		DialogueManager.show_dialogue_balloon(a5s3, "start")

func _on_dialogue_start(_resource):
	can_interact = false

func _on_dialogue_finish(_resource):
	can_interact = true

func _start_scene() -> void:
	GameState.load_game()

func get_scene_type() -> String:
	return "game"

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "player_mateo":
		tip_interact.visible = true
		can_interact = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "player_mateo":
		tip_interact.visible = false
		can_interact = false
