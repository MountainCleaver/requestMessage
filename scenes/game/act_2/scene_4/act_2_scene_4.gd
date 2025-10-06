extends Node2D

# === PRELOADS ===
const A_2S_4 = preload("res://dialogues/act_2/scene_4/a2s4.dialogue") # Dialogue file for this scene
const WENDY_HOUSE = preload("res://scenes/game/act_2/scene_4/wendy_house.tscn")

# === NODES ===
@onready var locations: Node2D = $location
var wendy: Node2D = null

# === OBJECTIVES ===
var scene_objectives = [
	{"ID": 1, "text": "Find a way to reach Danilo"},
]

# === STATE ===
var current_location: Node = null
var choice_made: String = ""


# ===================
# SCENE STARTUP
# ===================
func _ready() -> void:
	GameState.load_game()
	switch_location(WENDY_HOUSE)
	_start_scene()


func _start_scene() -> void:
	# Wendy's initial thoughts (non-interactive)
	DialogueManager.show_dialogue_balloon(A_2S_4, "wendy_intro")

	# After initial dialogue, show choice options
	await get_tree().create_timer(3).timeout
	_show_choices()


# ===================
# CHOICE HANDLER
# ===================
func _show_choices() -> void:
	# These choices can appear via a UI prompt or dialogue choice system
	var choices = [
		{"id": "chat_danilo", "text": "Chat Danilo"},
		{"id": "chat_mira", "text": "Chat Mira"}
	]

	ChoiceUI.show_choices(choices)
	ChoiceUI.choice_selected.connect(_on_choice_selected)


func _on_choice_selected(choice_id: String) -> void:
	choice_made = choice_id
	match choice_id:
		"chat_danilo":
			_handle_chat_danilo()
		"chat_mira":
			_handle_chat_mira()


# ===================
# CHOICE OUTCOMES
# ===================
func _handle_chat_danilo() -> void:
	# Scene when Wendy tries to chat Danilo, but only "sent" is shown
	DialogueManager.show_dialogue_balloon(A_2S_4, "chat_danilo_sent")
	await DialogueManager.dialogue_finished
	_show_after_choice_summary()


func _handle_chat_mira() -> void:
	# Wendy chats with Mira (Danilo’s mother)
	DialogueManager.show_dialogue_balloon(A_2S_4, "chat_mira_start")
	await DialogueManager.dialogue_finished
	_show_after_choice_summary()


# ===================
# AFTER CHOICE
# ===================
func _show_after_choice_summary() -> void:
	# Optional summary or transition to next scene
	GameState.update_objective_complete(1)
	DialogueManager.show_dialogue_balloon(A_2S_4, "wendy_reflect")
	# You can transition to next scene here
	# SceneTransition.fade_to("res://scenes/game/act_2/scene_5/act_2_scene_5.tscn")


# ===================
# LOCATION HANDLER
# ===================
func switch_location(scene: PackedScene) -> void:
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()

	current_location = scene.instantiate()
	locations.add_child(current_location)

	wendy = current_location.get_node("wendy")
