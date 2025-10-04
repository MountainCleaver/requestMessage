extends Node2D

# PRELOADS
const A_2S_1 = preload("res://dialogues/act_2/scene_1/a2s1.dialogue")
const DANILO_ROOM = preload("res://scenes/game/act_1/scene_4/danilo_room.tscn")

@onready var locations: Node2D = $locations
var player_danilo: CharacterBody2D = null

# OBJECTIVES
var scene_objectives = [
	{"ID": 1, "text": "Chat Wendy about what happened"},
]

# FLAGS


# STATES
var current_location: Node = null

func _ready() -> void:
	switch_location(DANILO_ROOM)

	_start_scene()

# ===================
# SCENE START
# ===================
func _start_scene() -> void:
	DialogueManager.show_dialogue_balloon(A_2S_1, "start")
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])

# ===================
# LOCATION 
# ===================
func switch_location(scene: PackedScene) -> void:
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()
	current_location = scene.instantiate()
	locations.add_child(current_location)
	player_danilo = current_location.get_node("player_danilo")

# ===================
# SEND CHAT
# ===================
func send_chat(chat_name: String, sender: String, text: String) -> void:
	SignalBus.chat_message_received.emit(chat_name, sender, text)
