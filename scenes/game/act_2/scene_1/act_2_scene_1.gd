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
	print("[ACT 2 SCENE 1] Ready called.")
	switch_location(DANILO_ROOM)
	_start_scene()

# ===================
# SCENE START
# ===================
func _start_scene() -> void:
	print("[ACT 2 SCENE 1] Starting scene setup...")
	GameState.load_chat_state()

	if not GameState.checked_sched:
		print("[TEST MODE] Fake Act 1 data loaded.")
		_fake_load_act1_state()

		# Open phone immediately on Unknown Sender chat
		await get_tree().create_timer(1.0).timeout
		Hud.phone_intro()
		await get_tree().create_timer(1.0).timeout
		SignalBus.chat_opened.emit("unknown_sender")

		# Simulate message from Unknown Sender
		await get_tree().create_timer(2.0).timeout
		SignalBus.chat_message_received.emit("unknown_sender", "unknown_sender", "Hello again, Danilo. Did you miss me?")
	else:
		print("[NORMAL MODE] Continuing from saved Act 1.")
		DialogueManager.show_dialogue_balloon(A_2S_1, "start")
		ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
		Hud.phone_intro()

# ===================
# FAKE STATE FOR TESTING
# ===================
func _fake_load_act1_state() -> void:
	print("[FAKE STATE] Simulating finished Act 1.")
	GameState.checked_sched = true
	GameState.chat_objectives_added = true
	GameState.wendy_reply_shown = true
	GameState.mira_reply_shown = true
	GameState.wendy_opened = true
	GameState.mira_opened = true
	GameState.gc_opened = true
	GameState.unknown_sender_opened = true
	GameState.set1_objective_done = true
	GameState.objective8_added = true
	GameState.has_gone_home = true
	GameState.current_act = "act_2"
	GameState.current_scene = "scene_1"

	# Load chat data if exists
	GameState.load_chat_state()

# ===================
# LOCATION HANDLER
# ===================
func switch_location(scene: PackedScene) -> void:
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()

	current_location = scene.instantiate()
	locations.add_child(current_location)

	player_danilo = current_location.get_node("player_danilo")
	print("[ACT 2 SCENE 1] Switched location to:", current_location.name)
