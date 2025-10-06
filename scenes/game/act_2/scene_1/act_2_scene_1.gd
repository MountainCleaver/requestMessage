extends Node2D

# === PRELOADS ===
const A_2S_1 = preload("res://dialogues/act_2/scene_1/a2s1.dialogue")
const DANILO_ROOM = preload("res://scenes/game/act_1/scene_4/danilo_room.tscn")

# === NODES ===
@onready var locations: Node2D = $locations
var player_danilo: CharacterBody2D = null

# === OBJECTIVES ===
var scene_objectives = [
	{"ID": 1, "text": "Chat Wendy about what happened"},
]

# === STATE ===
var current_location: Node = null

func _ready() -> void:
	GameState.load_game()

	switch_location(DANILO_ROOM)

	_start_scene()

# ===================
# SCENE START
# ===================
func _start_scene() -> void:
	GameState.load_game()
	SignalBus.unknown_sender_unlocked = GameState.unknown_sender_opened

	if GameState.unknown_sender_opened:
		# Skip dialogue, show phone + chat automatically
		Hud.show_phone_with_unknown_sender()
		await get_tree().create_timer(1).timeout 
		DialogueManager.show_dialogue_balloon(A_2S_1, "start")


# ===================
# LOCATION HANDLER
# ===================
func switch_location(scene: PackedScene) -> void:
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()

	current_location = scene.instantiate()
	locations.add_child(current_location)

	player_danilo = current_location.get_node("player_danilo")

# ===================
# INPUT HANDLER (if needed)
# ===================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_danilo:
		if player_danilo.get_parent().in_room_area:
			# Example: move to some location or trigger scene events
			pass
