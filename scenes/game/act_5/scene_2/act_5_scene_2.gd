extends Node2D

@onready var player_mateo: CharacterBody2D = $mateo_home/ysort/player_mateo
@onready var npc_gino: CharacterBody2D = $mateo_home/ysort/npc_gino
@onready var npc_matet: CharacterBody2D = $mateo_home/ysort/npc_matet
var A_5S_2: Resource
@onready var tip_interact: Sprite2D = $mateo_home/ysort/player_mateo/tip_interact


func _ready() -> void:
	_load_dialogue()
	$mateo_home/ysort/npc_gino/AnimatedSprite2D.play("idle_left")
	$mateo_home/ysort/npc_matet/AnimatedSprite2D.play("idle_right")
	DialogueManager.show_dialogue_balloon(A_5S_2, "start")

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_5/scene_2/a5s2_en.dialogue"
	else:
		path = "res://dialogues/act_5/scene_2/a5s2.dialogue"
	
	A_5S_2 = load(path)

func _input(event: InputEvent) -> void:
	if event.is_action("interact"):
		tip_interact.visible = false
		ObjectiveManager.complete_objective(1)
		await get_tree().create_timer(0.2).timeout
		Hud.hide_objectives()
		Hud.clear_objectives()
		act_5_scene_2_done()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "player_mateo":
		tip_interact.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "player_mateo":
		tip_interact.visible = false

func act_5_scene_2_done() -> void:
	SaveManager.game_save.current_act = "act_5"
	SaveManager.game_save.current_scene = "scene_2"
	SaveManager.save_game()
	SignalBus.act_num_scene_num_done.emit("act_5", "scene_2", "res://scenes/game/act_5/scene_3/act_5_scene_3.tscn")
		
 