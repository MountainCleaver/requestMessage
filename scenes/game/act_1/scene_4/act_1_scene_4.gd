extends Node2D

# PRELOADS
const A_1S_4 = preload("res://dialogues/act_1/scene_4/a1s4.dialogue")
const DANILO_NEIGHBORHOOD = preload("res://scenes/game/act_1/scene_4/danilo_neighborhood.tscn")
const DANILO_ROOM = preload("res://scenes/game/act_1/scene_4/danilo_room.tscn")
const DANILO_LOCK = preload("res://scenes/game/lock_screen.tscn")

# NODES
@onready var locations: Node2D = $locations
@onready var ChatHistory = get_node("/root/ChatHistory")
var player_danilo: CharacterBody2D = null

# OBJECTIVES
var scene_objectives = [
	{"ID": 1, "text": "Check psych appointment schedule"},
	{"ID": 2, "text": "Check message from Wendy"},
	{"ID": 3, "text": "Check message from Mira"},
	{"ID": 4, "text": "Check message from GC"},
	{"ID": 5, "text": "Close/Lock phone"},
	{"ID": 6, "text": "Go Home"},
	{"ID": 7, "text": "Check the phone again"},
	{"ID": 8, "text": "Check the unknown number and its request message"}
]

# FLAGS
var checked_sched : bool = false
var chat_objectives_added : bool = false
var wendy_reply_shown: bool = false
var mira_reply_shown : bool = false
var wendy_opened: bool = false
var mira_opened: bool = false
var gc_opened: bool = false
var unknown_sender_opened: bool = false
var set1_objective_done: bool = false
var objective8_added: bool = false
var has_gone_home: bool = false
var final_objectives_done: bool = false

# STATES
var current_location: Node = null
var buzz_timer: Timer
var lock_screen_instance: Control = null

func _ready() -> void:
	_game_state_flow()
	
	switch_location(DANILO_NEIGHBORHOOD)

	# Buzz Timer setup
	buzz_timer = Timer.new()
	add_child(buzz_timer)
	buzz_timer.wait_time = 1.5
	buzz_timer.one_shot = false
	buzz_timer.connect("timeout", Callable(self, "_on_buzz_timeout"))

	# Connect SignalBus signals
	SignalBus.sched_opened.connect(_on_sched_opened)
	SignalBus.app_chat_opened.connect(_on_app_chat_opened)
	SignalBus.chat_opened.connect(_on_chat_opened)
	SignalBus.chat_message_sent.connect(_on_chat_message_sent)
	SignalBus.chat_closed.connect(_on_chat_closed)

	_start_scene()

# ===================
# SCENE START
# ===================
func _start_scene() -> void:
	DialogueManager.show_dialogue_balloon(A_1S_4, "start")
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	await get_tree().create_timer(1.0).timeout
	show_initial_lock_screen()

func _game_state_flow() -> void:
	# PUT THIS AT THE BEGINNING OF FUNC _READY
	GameState.current_act = "act_1"
	GameState.current_scene = "scene_4"
	GameState.save_game()
	GameState.overwrite_current_scene_keep_previous()
	
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
# BUZZ AUDIO
# ===================
func start_buzz() -> void:
	if not current_location:
		return
	var buzz = current_location.get_node_or_null("buzz_audio")
	if buzz:
		buzz.play()
		buzz_timer.start()

func stop_buzz() -> void:
	if not current_location:
		return
	var buzz = current_location.get_node_or_null("buzz_audio")
	if buzz:
		buzz.stop()
		buzz_timer.stop()

func _on_buzz_timeout() -> void:
	if not current_location:
		return
	var buzz = current_location.get_node_or_null("buzz_audio")
	if buzz:
		buzz.play()

# ===================
# SIGNALBUS HANDLERS
# ===================
func _on_sched_opened() -> void:
	open_sched()

func _on_app_chat_opened() -> void:
	if has_gone_home and not objective8_added:
		ObjectiveManager.add_objective(scene_objectives[7]["ID"], scene_objectives[7]["text"], Color.RED)
		objective8_added = true
		DialogueManager.show_dialogue_balloon(A_1S_4, "after_open_phone_2")

func _on_chat_opened(chat_name: String) -> void:
	match chat_name:
		"wendy":
			open_chat_generic("wendy", "reply_wendy", scene_objectives[1]["ID"])
		"mira":
			open_chat_generic("mira", "reply_mira", scene_objectives[2]["ID"])
		"group_chat":
			open_chat_generic("group_chat", "reply_gc", scene_objectives[3]["ID"])
		"unknown_sender":
			open_chat_generic("unknown_sender", "chat_unknown_sender")

			unknown_sender_opened = true
			
			if has_gone_home:
				ObjectiveManager.complete_objective(scene_objectives[7]["ID"])
				final_objectives_done = true
			
				if lock_screen_instance:
					lock_screen_instance.objectives_done = true
				
				await get_tree().create_timer(5).timeout
				Hud.hide_objectives()
				Hud.phone_outro()
				scene_4_done()

func _on_chat_closed(chat_name: String) -> void:
	print("%s chat closed" % chat_name)

func _on_chat_message_sent(chat_name: String) -> void:
	match chat_name:
		"wendy":
			if not wendy_reply_shown:
				wendy_reply_shown = true
				DialogueManager.show_dialogue_balloon(A_1S_4, "reply")
		"mira":
			if not mira_reply_shown:
				mira_reply_shown = true
				DialogueManager.show_dialogue_balloon(A_1S_4, "reply_mira_answer")

# ===================
# CHAT HELPERS
# ===================
func get_chat_flag(chat_name: String) -> bool:
	match chat_name:
		"wendy": return wendy_opened
		"mira": return mira_opened
		"group_chat": return gc_opened
		"unknown_sender": return unknown_sender_opened
		_: return false

func set_chat_flag(chat_name: String, value: bool) -> void:
	match chat_name:
		"wendy": wendy_opened = value
		"mira": mira_opened = value
		"group_chat": gc_opened = value
		"unknown_sender": unknown_sender_opened = value

func open_chat_generic(chat_name: String, dialogue_key: String, objective_id: int = -1) -> void:
	if not checked_sched:
		return
	if get_chat_flag(chat_name):
		return
	set_chat_flag(chat_name, true)
	if objective_id != -1:
		ObjectiveManager.complete_objective(objective_id)
	DialogueManager.show_dialogue_balloon(A_1S_4, dialogue_key)
	check_add_lock_objective()

# ===================
# OBJECTIVE LOGIC
# ===================
func open_sched() -> void:
	if not checked_sched:
		checked_sched = true
		ObjectiveManager.complete_objective(scene_objectives[0]["ID"])
		DialogueManager.show_dialogue_balloon(A_1S_4, "checked_schedule")

	if not chat_objectives_added:
		chat_objectives_added = true
		ObjectiveManager.add_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"])
		ObjectiveManager.add_objective(scene_objectives[2]["ID"], scene_objectives[2]["text"])
		ObjectiveManager.add_objective(scene_objectives[3]["ID"], scene_objectives[3]["text"])

func all_chats_checked() -> bool:
	return wendy_opened and mira_opened and gc_opened

func check_add_lock_objective() -> void:
	if all_chats_checked() and not set1_objective_done:
		ObjectiveManager.add_objective(scene_objectives[4]["ID"], scene_objectives[4]["text"])

func _on_last_objective_lock_pressed() -> void:
	if not set1_objective_done:
		set1_objective_done = true
		ObjectiveManager.complete_objective(scene_objectives[4]["ID"])
		Hud.phone_outro()
		Hud.clear_objectives()
		ObjectiveManager.add_objective(scene_objectives[5]["ID"], scene_objectives[5]["text"])

# ===================
# LOCK SCREEN
# ===================
func _show_lock_screen() -> void:
	if lock_screen_instance and is_instance_valid(lock_screen_instance):
		lock_screen_instance.visible = true
		return
	print("Danilo lock screen shown")

func _on_lock_screen_pressed() -> void:
	print("Lock screen button pressed")
	if lock_screen_instance:
		lock_screen_instance.visible = false

func _on_phone_locked() -> void:
	print("PHONE_LOCKED SIGNAL RECEIVED - Showing lock screen again")
	_show_lock_screen()

func show_initial_lock_screen() -> void:
	_show_lock_screen()

# ===================
# ROOM SWITCH
# ===================
func _switch_to_danilo_room() -> void:
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	switch_location(DANILO_ROOM)

	ObjectiveManager.complete_objective(scene_objectives[5]["ID"])
	ObjectiveManager.add_objective(scene_objectives[6]["ID"], scene_objectives[6]["text"])
	DialogueManager.show_dialogue_balloon(A_1S_4, "after_home")

	SignalBus.unknown_sender_unlocked = true
	has_gone_home = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_danilo:
		if player_danilo.get_parent().in_bahay_area:
			_switch_to_danilo_room()

# ===================
# SCENE COMPLETE
# ===================
func scene_4_done() -> void:
	Hud.hide_objectives()
	Hud.clear_objectives()
	GameState.save_game()
	SignalBus.next_scene.emit("res://scenes/game/act_2_title_scene.tscn")
	print("act 1 scene 4 is done. ACT 1 DONE !!!!!!!!!!!!!!!!!!")
