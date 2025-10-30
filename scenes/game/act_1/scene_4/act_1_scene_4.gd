extends Node2D

# PRELOADS
var A_1S_4: Resource
const DANILO_NEIGHBORHOOD = preload("res://scenes/game/act_1/scene_4/danilo_neighborhood.tscn")
const DANILO_ROOM = preload("res://scenes/game/act_1/scene_4/danilo_room.tscn")
const DANILO_LOCK = preload("res://scenes/game/lock_screen.tscn")

# NODES
@onready var locations: Node2D = $locations
var player_danilo: CharacterBody2D = null
var bgm_room: AudioStreamPlayer = null

# OBJECTIVES
var scene_objectives = [
	{"ID": 1, "text": "Check psych appointment schedule"},
	{"ID": 2, "text": "Check message from Wendy"},
	{"ID": 3, "text": "Check message from Mira"},
	{"ID": 4, "text": "Check message from GC"},
	{"ID": 5, "text": "Close/Lock phone"},
	{"ID": 6, "text": "Go Home"},
	{"ID": 7, "text": "Check the phone again"},
	{"ID": 8, "text": "[shake]Check the unknown number and its request message[/shake]"}
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
var _in_reflection := false
var in_bahay_area: bool = false

func _ready() -> void:
	_game_state_flow()
	_load_dialogue()
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
	SignalBus.chat_closed.connect(_on_chat_closed)
	SignalBus.unknown_sender_label_visible = true

	if DialogueManager:
		DialogueManager.connect("dialogue_ended", Callable(self, "_on_dialogue_ended"))

	_start_scene()

# ===================
# LOAD DIALOGUE
# ===================
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_1/scene_4/a1s4_en.dialogue"
	else:
		path = "res://dialogues/act_1/scene_4/a1s4.dialogue"
	A_1S_4 = load(path)

# ===================
# SCENE START
# ===================
func _start_scene() -> void:
	DialogueManager.show_dialogue_balloon(A_1S_4, "start")
	await DialogueManager.dialogue_ended
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	await get_tree().create_timer(1.0).timeout
	show_initial_lock_screen()

func _game_state_flow() -> void:
	FlashlightManager.set_current_scene("act_1", "scene_4")
	FlashlightManager.disable_flashlights()
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

	var bahay_area = current_location.get_node_or_null("bahay")
	if bahay_area:
		if not bahay_area.is_connected("body_entered", Callable(self, "_on_bahay_body_entered")):
			bahay_area.connect("body_entered", Callable(self, "_on_bahay_body_entered"))
		if not bahay_area.is_connected("body_exited", Callable(self, "_on_bahay_body_exited")):
			bahay_area.connect("body_exited", Callable(self, "_on_bahay_body_exited"))


# ===================
# REFLECTION CHOICE HANDLER
# ===================
func _on_dialogue_ended(resource = null) -> void:
	if not _in_reflection:
		_in_reflection = true
		var choice = SaveManager.get_moral_choice("act_1_scene_3")
		if choice == "relief":
			DialogueManager.show_dialogue_balloon(A_1S_4, "option_relief")
		elif choice == "restless":
			DialogueManager.show_dialogue_balloon(A_1S_4, "option_restless")
		else:
			DialogueManager.show_dialogue_balloon(A_1S_4, "option_restless")

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
				await get_tree().create_timer(0.8).timeout
				bgm_room = current_location.get_node_or_null("BGMRoom")
				if bgm_room:
					bgm_room.stop()
				scene_4_done()

func _on_chat_closed(chat_name: String) -> void:
	print("%s chat closed" % chat_name)

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
	bgm_room = current_location.get_node_or_null("BGMRoom")
	if bgm_room:
		bgm_room.play()
	ObjectiveManager.complete_objective(scene_objectives[5]["ID"])
	ObjectiveManager.add_objective(scene_objectives[6]["ID"], scene_objectives[6]["text"])
	DialogueManager.show_dialogue_balloon(A_1S_4, "after_home")
	SignalBus.unknown_sender_unlocked = true
	has_gone_home = true

# ===================
# NEIGHBORHOOD TRIGGERS
# ===================
func _on_bahay_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		in_bahay_area = true 
		SignalBus.in_npc.emit("bahay")

func _on_bahay_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		in_bahay_area = false 
		SignalBus.out_npc.emit("bahay")

# ===================
# INPUT
# ===================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_danilo:
		if in_bahay_area:
			_switch_to_danilo_room()

# ===================
# SCENE COMPLETE
# ===================
func scene_4_done() -> void:
	Hud.hide_objectives()
	Hud.clear_objectives()
	SaveManager.game_save.current_act = "act_1"
	SaveManager.game_save.current_scene = "scene_4"
	GameState.save_game()
	SignalBus.act_num_scene_num_done.emit("act_1", "scene_4", "res://scenes/game/act_2_title_scene.tscn")
	print("ACT 1 SCENE 4 DONE. ACT 1 DONE!")
