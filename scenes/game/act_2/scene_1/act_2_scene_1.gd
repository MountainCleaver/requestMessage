extends Node2D

# === PRELOADS ===
var A_2S_1: Resource
const DANILO_ROOM = preload("res://scenes/game/act_1/scene_4/danilo_room.tscn")
const NARRATION_PANEL = preload("res://helpers/narration_panel.tscn")
const PHONE_INCOMING_CALL = preload("res://scenes/game/phone_incoming_call.tscn")

# === NODES ===
@onready var locations: Node2D = $locations
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# === DYNAMIC NODES (ASSIGNED AFTER SCENE LOAD) ===
var bed_area: Area2D = null
var player_danilo: CharacterBody2D = null
var tip_interact: Sprite2D = null
var sleep_marker: Marker2D = null

# === OBJECTIVES ===
var scene_objectives = [
	{"ID": 1, "text": "Chat Wendy about what happened"},
	{"ID": 2, "text": "Go to bed"},
	{"ID": 3, "text": "Close (lock) the phone and sleep"},
]

# === LOCAL STATE ===
var chat_open: bool = false
var phone_showing: bool = false
var lock_screen_active: bool = false
var phone_main_active: bool = false
var unknown_sender_opened: bool = false
var current_act: String = "act_2"
var current_scene: String = "scene_1"

# === FLAGS ===
var _dialogue_handled: bool = false
var wendy_opened: bool = false
var danilo_choice_shown: bool = false
var wendy_reply_shown: bool = false
var inside_bed: bool = false
var can_interact: bool = true
var call_with_unknown_sender_done: bool = false
var call_end_disabled : bool = false
var current_location: Node = null
var buzz_timer: Timer
var phone_instance: Control = null
var call_rejected : bool = false

# === SIGNALS ===
signal unknown_sender_calling

# ===================
# READY
# ===================
func _ready():
	_game_state_flow()
		
	switch_location(DANILO_ROOM)
	_start_scene()
	_load_dialogue()
	
	# === SIGNAL CONNECTIONS ===
	if not unknown_sender_calling.is_connected(_on_unknown_sender_calling):
		unknown_sender_calling.connect(_on_unknown_sender_calling)
	if not SignalBus.player_answered_call.is_connected(_on_answered_call):
		SignalBus.player_answered_call.connect(_on_answered_call)
	if not SignalBus.player_rejected_call.is_connected(_on_rejected_call):
		SignalBus.player_rejected_call.connect(_on_rejected_call)
	if not SignalBus.call_done.is_connected(_on_call_done):
		SignalBus.call_done.connect(_on_call_done)

	# Connect dialogue ended
	if not DialogueManager.is_connected("dialogue_ended", Callable(self, "_on_dialogue_ended")):
		DialogueManager.connect("dialogue_ended", Callable(self, "_on_dialogue_ended"))

	# Connect chat signals
	if not SignalBus.chat_opened.is_connected(_on_chat_opened):
		SignalBus.chat_opened.connect(_on_chat_opened)
	if not SignalBus.type_message_clicked.is_connected(_on_type_message_clicked):
		SignalBus.type_message_clicked.connect(_on_type_message_clicked)
	if not SignalBus.chat_message_sent.is_connected(_on_chat_message_sent):
		SignalBus.chat_message_sent.connect(_on_chat_message_sent)

	SignalBus.last_appointment_selected = "appointment_1"
	SignalBus.emit_signal("appointment_selected", "appointment_1")
	
	# Buzz Timer setup
	buzz_timer = Timer.new()
	add_child(buzz_timer)
	buzz_timer.wait_time = 1.5
	buzz_timer.one_shot = false
	buzz_timer.connect("timeout", Callable(self, "_on_buzz_timeout"))

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_2/scene_1/a2s1_en.dialogue"
	else:
		path = "res://dialogues/act_2/scene_1/a2s1.dialogue"
	
	A_2S_1 = load(path)
# ===================
# START SCENE
# ===================
func _start_scene() -> void:
	chat_open = false
	SignalBus.optional_chats_locked = false

	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])

	await get_tree().create_timer(1).timeout
	DialogueManager.show_dialogue_balloon(A_2S_1, "start")

	if tip_interact:
		tip_interact.visible = false
	if bed_area:
		bed_area.monitoring = false
		
func _game_state_flow() -> void:
	FlashlightManager.set_current_scene("act_2", "scene_1")
	FlashlightManager.disable_flashlights()
	# PUT THIS AT THE BEGINNING OF FUNC _READY
	GameState.load_game()
	GameState.current_act = "act_2"
	GameState.current_scene = "scene_1"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()
	
# ===================
# DIALOGUE ENDED
# ===================
func _on_dialogue_ended(resource: DialogueResource) -> void:
	if _dialogue_handled:
		return
	_dialogue_handled = true

	TransitionFade.transition()
	await SignalBus.on_transition_finished

	switch_location(NARRATION_PANEL)
	await get_tree().process_frame

	var lines = [
		"There was an unease he couldn’t explain.",
		"A name surfaced in his thoughts.",
		"Familiar yet distant."
	]

	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()

	TransitionFade.transition()
	await SignalBus.on_transition_finished

	switch_location(DANILO_ROOM)
	await get_tree().process_frame
	print("Returned to Danilo room")

	DialogueManager.show_dialogue_balloon(A_2S_1, "reply_danilo_4")

# ===================
# CHAT SIGNAL HANDLERS
# ===================
func _on_chat_opened(chat_name: String) -> void:
	if chat_name == "wendy" and not wendy_opened:
		wendy_opened = true

func _on_chat_message_sent(chat_name: String) -> void:
	if chat_name == "wendy" and not danilo_choice_shown:
		danilo_choice_shown = true
		DialogueManager.show_dialogue_balloon(A_2S_1, "choices_danilo_1")

func _on_type_message_clicked(chat_name: String) -> void:
	if chat_name == "wendy" and danilo_choice_shown and not wendy_reply_shown:
		wendy_reply_shown = true
		ObjectiveManager.complete_objective(scene_objectives[0]["ID"])
		DialogueManager.show_dialogue_balloon(A_2S_1, "reply_wendy_1")

# ===================
# POST PHONE OUTRO NARRATION
# ===================
func _after_phone_outro_narration() -> void:
	Hud.phone_outro()
	Hud.hide_objectives()
	
	await get_tree().process_frame
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	switch_location(NARRATION_PANEL)
	await get_tree().process_frame
	Hud.phone_outro()
	var lines = ["Danilo contemplates everything that happened today."]

	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()

	TransitionFade.transition()
	await SignalBus.on_transition_finished
	switch_location(DANILO_ROOM)
	await get_tree().process_frame

	DialogueManager.show_dialogue_balloon(A_2S_1, "thoughts_danilo_2")

	ObjectiveManager.add_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"])
	activate_bed()

# ===================
# LOCATION HANDLER
# ===================
func switch_location(scene: PackedScene) -> void:
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()

	current_location = scene.instantiate()
	locations.add_child(current_location)

	player_danilo = null
	tip_interact = null
	bed_area = null
	sleep_marker = null

	if current_location.has_node("player_danilo"):
		player_danilo = current_location.get_node("player_danilo")

		if player_danilo.has_node("tip_interact"):
			tip_interact = player_danilo.get_node("tip_interact")
			tip_interact.visible = false

	if current_location.has_node("bed_area"):
		bed_area = current_location.get_node("bed_area")
	else:
		for child in current_location.get_children():
			if child.has_node("bed_area"):
				bed_area = child.get_node("bed_area")
				break

	if current_location.has_node("sleep_marker"):
		sleep_marker = current_location.get_node("sleep_marker")
	else:
		for child in current_location.get_children():
			if child.has_node("sleep_marker"):
				sleep_marker = child.get_node("sleep_marker")
				break

	if bed_area and not bed_area.body_entered.is_connected(_on_bed_area_body_entered):
		bed_area.body_entered.connect(_on_bed_area_body_entered)
	if bed_area and not bed_area.body_exited.is_connected(_on_bed_area_body_exited):
		bed_area.body_exited.connect(_on_bed_area_body_exited)

# ===================
# BED INTERACTION
# ===================
func activate_bed() -> void:
	if bed_area:
		bed_area.monitoring = true

func _on_bed_area_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo" and tip_interact:
		tip_interact.visible = true
		inside_bed = true

func _on_bed_area_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo" and tip_interact:
		tip_interact.visible = false
		inside_bed = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and inside_bed and can_interact:
		can_interact = false
		_go_to_sleep()

# ===================
# SLEEP SEQUENCE
# ===================
func _go_to_sleep() -> void:
	print("Danilo is going to sleep...")

	if not player_danilo:
		print("ERROR: player_danilo is null!")
		return
	if not sleep_marker:
		print("ERROR: sleep_marker is null!")
		return

	player_danilo.animation_locked = true
	player_danilo.get_node("CollisionShape2D").disabled = true
	player_danilo.position = sleep_marker.position

	var anim_sprite: AnimatedSprite2D = player_danilo.get_node("AnimatedSprite2D")
	anim_sprite.play("sleep")

	player_danilo.can_move = false
	ObjectiveManager.complete_objective(scene_objectives[1]["ID"])

	await get_tree().create_timer(3).timeout
	DialogueManager.show_dialogue_balloon(A_2S_1, "choices_danilo_2")
	
func _on_open_phone():
	stop_buzz()
	Hud.show_phone_with_unknown_sender()  

# ===================
# UNKNOWN SENDER CALL SYSTEM
# ===================
func _on_unknown_sender_calling() -> void:
	var lockscreen = Hud.get_node("Control/phone/MarginContainer")
	for node in lockscreen.get_children():
		node.visible = false

	var phone_call_instance = PHONE_INCOMING_CALL.instantiate()
	lockscreen.add_child(phone_call_instance)
	phone_instance = phone_call_instance
	
func _on_call_done() -> void:
	var lockscreen = Hud.get_node("Control/phone/MarginContainer")
	for node in lockscreen.get_children():
		node.visible = true

func _on_answered_call() -> void:
	DialogueManager.show_dialogue_balloon(A_2S_1, "answer_call")
	await DialogueManager.dialogue_ended
	_on_answered_call_narration_panel()

func _on_answered_call_narration_panel() -> void:
	TransitionFade.transition()
	await SignalBus.on_transition_finished

	switch_location(NARRATION_PANEL)
	await get_tree().process_frame

	var lines = [
		"Danilo tries to make sense of the call,",
		"but it ends as if it was never there."
	]

	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	scene_1_done()

func _on_rejected_call() -> void:
	if call_rejected:
		return
	call_rejected = true
	DialogueManager.show_dialogue_balloon(A_2S_1, "reject_call")
	await DialogueManager.dialogue_ended
	_on_rejected_call_narration_panel()

func _on_rejected_call_narration_panel() -> void:
	TransitionFade.transition()
	await SignalBus.on_transition_finished

	switch_location(NARRATION_PANEL)
	await get_tree().process_frame

	var lines = [
		"The call ends unanswered,",
		"and the darkness leans in as he sleeps."
	]

	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	scene_1_done()

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

func _prevent_end_call_while_dialog_is_not_finished () -> void:
	if not call_end_disabled:
		Hud.get_node("Control/phone/MarginContainer/incoming_call/HBoxContainer2/Button").disabled = true
		call_end_disabled = true
	else:
		Hud.get_node("Control/phone/MarginContainer/incoming_call/HBoxContainer2/Button").disabled = false
		call_end_disabled = false

# ===================
# SCENE COMPLETE
# ===================
func scene_1_done() -> void:
	Hud.hide_objectives()
	Hud.clear_objectives()
	SaveManager.game_save.current_act = "act_2"
	SaveManager.game_save.current_scene = "scene_1"
	SaveManager.save_game()
	GameState.save_game()
	print("ACT 2 SCENE 1 DONE")
	SignalBus.act_num_scene_num_done.emit("act_2", "scene_1", "res://scenes/game/act_2/scene_2/act_2_scene_2.tscn")
		
 