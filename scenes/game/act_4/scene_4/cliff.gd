extends Node2D

const A_4S_4 := preload("res://dialogues/act_4/scene_4/a4s4.dialogue")

@onready var phone_trigger: Area2D = $phone_trigger
@onready var player_danilo: CharacterBody2D = $"y-sorted/player_danilo"

var scene_objectives = [
	{"ID": 2, "text": "Find the last paper under the rocks"}
]

var unknown_sender_opened: bool = false
var phone_showing: bool = false
var lock_screen_active: bool = false
var phone_main_active: bool = false
var chat_open: bool = false

func _ready() -> void:

	if get_tree().has_meta("last_portal_name"):
		var last_portal_name = str(get_tree().get_meta("last_portal_name"))
		var target_portal = get_node_or_null(NodePath(last_portal_name))
		if target_portal:
			player_danilo.global_position = target_portal.global_position
			
			ObjectiveManager.complete_objective(1)
			print("Spawned player at:", target_portal.name)

	enable_phone_trigger()

	for objective in scene_objectives:
		ObjectiveManager.add_objective(objective["ID"], objective["text"])

func enable_phone_trigger() -> void:
	phone_trigger.visible = true
	phone_trigger.monitoring = true
	phone_trigger.set_deferred("monitorable", true)

func disable_phone_trigger() -> void:
	phone_trigger.monitoring = false
	phone_trigger.set_deferred("monitorable", false)
	phone_trigger.visible = false

func _on_phone_trigger_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return

	SignalBus.unknown_sender_unlocked = true
	phone_showing = true
	lock_screen_active = false
	phone_main_active = false
	chat_open = false

	if not unknown_sender_opened:
		Hud.show_phone_with_unknown_sender()
		await get_tree().create_timer(1.0).timeout
		player_danilo.force_cannot_move = true
		_on_chat_opened("unknown_sender")

	phone_trigger.monitoring = false
	phone_trigger.visible = false
	phone_trigger.set_deferred("monitorable", false)

	player_danilo.force_cannot_move = false
	player_danilo.can_move = true
	player_danilo.can_interact = true

func _on_chat_opened(chat_name: String) -> void:
	if chat_name == "unknown_sender" and not unknown_sender_opened:
		unknown_sender_opened = true
		DialogueManager.show_dialogue_balloon(A_4S_4, "unknown_message")
		await get_tree().create_timer(1.0).timeout

func act_4_scene_4_done() -> void:
	Hud.hide_objectives()
	Hud.clear_objectives()

	SaveManager.game_save.current_act = "act_4"
	SaveManager.game_save.current_scene = "scene_4"
	GameState.save_game()

	print("ACT 4 SCENE 4 DONE")

	# Emit signal to transition to the next scene
	SignalBus.act_num_scene_num_done.emit(
		"act_5", 
		"scene_1", 
		"res://scenes/game/act_5/scene_1/act_5_scene_5.tscn"
	)
