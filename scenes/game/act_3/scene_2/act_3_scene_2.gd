extends Node2D

@onready var player_danilo: CharacterBody2D = $"danilo_hometown_house/y-sorted/player_danilo"
@onready var animated_sprite_2d: AnimatedSprite2D = $"danilo_hometown_house/y-sorted/player_danilo/AnimatedSprite2D"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var marker_2d: Marker2D = $Marker2D
@onready var danilo_collision_shape_2d: CollisionShape2D = $"danilo_hometown_house/y-sorted/player_danilo/CollisionShape2D"
@onready var camera_2d: Camera2D = $Camera2D

@onready var window_1: Sprite2D = $danilo_hometown_house/map/window_1
@onready var window_2: Sprite2D = $danilo_hometown_house/map/window_2
@onready var window_3: Sprite2D = $danilo_hometown_house/map/window_3

@onready var window_area_1: Area2D = $window_areas/window_area_1
@onready var window_area_2: Area2D = $window_areas/window_area_2
@onready var window_area_3: Area2D = $window_areas/window_area_3

@onready var shock_sprite: Sprite2D = $"danilo_hometown_house/y-sorted/player_danilo/shock_sprite"

@onready var npc_shadowy_chaser: CharacterBody2D = $danilo_hometown_house/map/npc_shadowy_chaser
@onready var tension_anim: AnimationPlayer = $tension_anim

# BGM NODES
@onready var bgm_danilo: AudioStreamPlayer = $BGMDanilo
@onready var bgm_tension: AudioStreamPlayer = $BGMTension
@onready var sfx_close: AudioStreamPlayer = $SFX_CLOSE

var A_3S_2: Resource
const CHAT_ICON = preload("uid://vdiek8gwmqdx")
const BALLOON = preload("uid://2i4i7d4jd8qg")
const PHONE_INCOMING_CALL = preload("res://scenes/game/phone_incoming_call.tscn")

var wendy_open: bool = false
var wendy_opened: bool = false
var wendy_reply_shown: bool = false
var mira_open: bool = false
var unknown_sender_open : bool = false
var replied_to_wendy: bool = false
var replied_to_mira: bool = false
var call_with_wendy_done: bool = false

var chat_exit_disabled : bool = false
var call_end_disabled : bool = false

var window_1_closed : bool = false
var window_2_closed : bool = false
var window_3_closed : bool = false

signal wendy_calling
signal reply_finish
signal replied_to_mira_and_wendy
signal window_closed

var scene_objectives: Array[Dictionary] = [
	{"ID": 1, "text": "Reply to Wendy and Mira"},
	{"ID": 2, "text": "[shake]Close all the windows[/shake]"}
]

func _ready() -> void:
	_game_state_flow()
	_load_dialogue()
	# BGM: Play calm at the start, make sure tension is stopped
	bgm_danilo.play()

	reply_finish.connect(_on_reply_finished)
	wendy_calling.connect(_on_wendy_calling)
	window_closed.connect(_on_window_closed)
	SignalBus.chat_message_sent.connect(reply_to_chat)
	SignalBus.player_answered_call.connect(_on_answered_call)
	SignalBus.player_rejected_call.connect(_on_rejected_call)
	SignalBus.call_done.connect(_on_call_done)
	SignalBus.app_chat_opened.connect(_on_app_chat_opened)
	SignalBus.chat_opened.connect(_on_chat_opened)
	SignalBus.unknown_sender_unlocked = true
	SignalBus.unknown_sender_label_visible = false

	danilo_collision_shape_2d.disabled = true
	player_danilo.animation_locked = true
	player_danilo.force_cannot_move = true
	animated_sprite_2d.play("sitting")

	Hud.show_objectives()
	
	Hud.get_node("Control/phone/MarginContainer/lock_screen").clear_notifications()
	Hud.reset_phone_state("01:30", "PM")
	await get_tree().create_timer(1.0).timeout
	Hud.get_node("Control/phone/MarginContainer/lock_screen/Panel/lock").disabled = true

	add_notification(CHAT_ICON, "Chat", "2 missed calls from Mira")
	await get_tree().create_timer(1.0).timeout
	add_notification(CHAT_ICON, "Chat", "Wendy: Dan, you didn’t even inform me you were going home. We were worried, hindi ka sumasagot sa chats ko. Akala ko may nangyari na sayo")

	await get_tree().create_timer(1.0).timeout
	Hud.clear_objectives()
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	Hud.show_objectives()
	
	Hud.get_node("Control/phone/MarginContainer/lock_screen/Panel/lock").disabled = false
	
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_3/scene_2/a3s2_en.dialogue"
	else:
		path = "res://dialogues/act_3/scene_2/a3s2.dialogue"
	
	A_3S_2 = load(path)
	
func _on_chat_opened(chat_name: String) -> void:
	if chat_name == "wendy" and not wendy_opened:
		wendy_opened = true
		DialogueManager.show_dialogue_balloon(A_3S_2, "first_chat_wendy")

func _game_state_flow() -> void:
	# PUT THIS AT THE BEGINNING OF FUNC _READY
	FlashlightManager.set_current_scene("act_3", "scene_2")
	FlashlightManager.disable_flashlights()
	GameState.load_game()
	GameState.current_act = "act_3"
	GameState.current_scene = "scene_2"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		match player_danilo.current_npc:
			"window_1":
				if not window_1_closed:
					sfx_close.play()
					window_1.region_rect = Rect2(0,0,32,34)
					window_area_1.queue_free()
					window_1_closed = true;
					window_closed.emit()
			"window_2":
				if not window_2_closed:
					sfx_close.play()
					window_2.region_rect = Rect2(0,0,32,34)
					window_area_2.queue_free()
					window_2_closed = true;
					window_closed.emit()
			"window_3":
				if not window_3_closed:
					sfx_close.play()
					window_3.region_rect = Rect2(0,0,32,34)
					window_area_3.queue_free()
					window_3_closed = true;
					window_closed.emit()


func add_notification(image: Texture2D, app_name: String, notif_content: String) -> void:
	Hud.get_node("Control/phone/MarginContainer/lock_screen").add_notification(image, app_name, notif_content)

func reply_to_chat(chat_name: String) -> void:
	match chat_name:
		"wendy":
			if not wendy_open:
				DialogueManager.show_dialogue_balloon(A_3S_2, "reply_" + chat_name)
				wendy_open = true
		"mira":
			if not mira_open:
				DialogueManager.show_dialogue_balloon(A_3S_2, "reply_" + chat_name)
				mira_open = true
		"unknown":
			if not unknown_sender_open:
				DialogueManager.show_dialogue_balloon(A_3S_2, "unknown")
				unknown_sender_open = true

func _on_reply_finished() -> void:
	if replied_to_mira and replied_to_wendy:
		camera_2d.zoom.x = 3.0
		camera_2d.zoom.y = 3.0
		ObjectiveManager.complete_objective(scene_objectives[0]["ID"])
		Hud.phone_outro()
		# also clear current children of the margin container
		shadow_appear()
		GameState.save_game()

		# BGM: Stop calm, play tension
		bgm_danilo.stop()
		bgm_tension.play()

func _on_wendy_calling() -> void:
	var lockscreen = Hud.get_node("Control/phone/MarginContainer")
	for node in lockscreen.get_children():
		node.visible = false

	var phone_call_instance = PHONE_INCOMING_CALL.instantiate()
	lockscreen.add_child(phone_call_instance)

	phone_call_instance.set_caller("Wendy")
	
func _on_rejected_call() -> void:
	DialogueManager.show_dialogue_balloon(A_3S_2, "ignore_call")
	
func _on_answered_call() -> void:
	DialogueManager.show_dialogue_balloon(A_3S_2, "call_with_wendy")

func _on_call_done() -> void:
	var lockscreen = Hud.get_node("Control/phone/MarginContainer")
	for node in lockscreen.get_children():
		node.visible = true

func shadow_appear() -> void:
	animation_player.play("shadow_show")

func _close_windows_obj() -> void:
	ObjectiveManager.add_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"], Color.RED)
	player_danilo.last_direction = Vector2.DOWN;
	player_danilo.position = marker_2d.position
	player_danilo.animation_locked = false;

func enable_player_movement () -> void:
	player_danilo.force_cannot_move = false;
	danilo_collision_shape_2d.disabled = false; 

func _on_window_area_1_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("window_1")

func _on_window_area_1_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("window_1")

func _on_window_area_2_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("window_2")

func _on_window_area_2_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("window_2")

func _on_window_area_3_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("window_3")

func _on_window_area_3_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("window_3")

func _on_window_closed () -> void:
	if window_1_closed and window_2_closed and window_3_closed:
		ObjectiveManager.complete_objective(scene_objectives[1]["ID"])
		shadow_figure_vanish()
		shock_sprite.queue_free()
		#_remove_previous_chat_scene_for_unkown_sender()
		DialogueManager.show_dialogue_balloon(A_3S_2, "unknown")

func shadow_figure_vanish()->void:
	await get_tree().create_timer(3.0).timeout
	npc_shadowy_chaser.queue_free()
	
func _on_app_chat_opened () -> void:
	Hud.get_node("Control/phone/MarginContainer/lock_screen").clear_notifications()

func _prevent_chat_exit_while_dialoging () -> void:
	if not chat_exit_disabled:
		Hud.get_node("Control/phone/MarginContainer/app_chat_convo/screen/Panel/EXIT").disabled = true
		chat_exit_disabled = true
	else:
		Hud.get_node("Control/phone/MarginContainer/app_chat_convo/screen/Panel/EXIT").disabled = false
		chat_exit_disabled = false

func _prevent_end_call_while_dialog_is_not_finished () -> void:
	if not call_end_disabled:
		Hud.get_node("Control/phone/MarginContainer/incoming_call/HBoxContainer2/Button").disabled = true
		call_end_disabled = true
	else:
		Hud.get_node("Control/phone/MarginContainer/incoming_call/HBoxContainer2/Button").disabled = false
		call_end_disabled = false

func _remove_previous_chat_scene_for_unkown_sender() -> void:
	var app_chat = Hud.get_node("Control/phone/MarginContainer/app_chat")
	var app_chat_convo = Hud.get_node("Control/phone/MarginContainer/app_chat_convo")
	var phone_main = Hud.get_node("Control/phone/MarginContainer/phone")
	
	app_chat.queue_free()
	app_chat_convo.queue_free()
	phone_main.queue_free()

func _play_tension_anim() -> void:
	tension_anim.play("tension")

func _act_3_scene_2_done() -> void:
	print(SaveManager.get_moral_choice("act_3_scene_2"))
	SaveManager.game_save.current_act = "act_3"
	SaveManager.game_save.current_scene = "scene_2" 
	SaveManager.save_game()
	SignalBus.act_num_scene_num_done.emit("act_3", "scene_2", "res://scenes/game/act_3/scene_3/act_3_scene_3.tscn")
	Hud.clear_objectives();
	Hud.hide_objectives()
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
