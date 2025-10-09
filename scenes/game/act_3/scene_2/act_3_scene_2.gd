extends Node2D

@onready var player_danilo: CharacterBody2D = $"danilo_hometown_house/y-sorted/player_danilo"
@onready var animated_sprite_2d: AnimatedSprite2D = $"danilo_hometown_house/y-sorted/player_danilo/AnimatedSprite2D"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var marker_2d: Marker2D = $Marker2D
@onready var danilo_collision_shape_2d: CollisionShape2D = $"danilo_hometown_house/y-sorted/player_danilo/CollisionShape2D"

@onready var window_1: Sprite2D = $danilo_hometown_house/map/window_1
@onready var window_2: Sprite2D = $danilo_hometown_house/map/window_2
@onready var window_3: Sprite2D = $danilo_hometown_house/map/window_3

@onready var window_area_1: Area2D = $window_areas/window_area_1
@onready var window_area_2: Area2D = $window_areas/window_area_2
@onready var window_area_3: Area2D = $window_areas/window_area_3

@onready var shock_sprite: Sprite2D = $"danilo_hometown_house/y-sorted/player_danilo/shock_sprite"

@onready var npc_shadowy_chaser: CharacterBody2D = $danilo_hometown_house/map/npc_shadowy_chaser

const A_3S_2 = preload("uid://vpb3fshkkblr")
const CHAT_ICON = preload("uid://vdiek8gwmqdx")
const BALLOON = preload("uid://2i4i7d4jd8qg")
const PHONE_INCOMING_CALL = preload("res://scenes/game/phone_incoming_call.tscn")

var wendy_open: bool = false
var mira_open: bool = false
var replied_to_wendy: bool = false
var replied_to_mira: bool = false
var call_with_wendy_done: bool = false

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
	GameState.load_game()

	reply_finish.connect(_on_reply_finished)
	wendy_calling.connect(_on_wendy_calling)
	window_closed.connect(_on_window_closed)
	SignalBus.chat_message_sent.connect(reply_to_chat)
	SignalBus.player_answered_call.connect(_on_answered_call)
	SignalBus.call_done.connect(_on_call_done)
	# SignalBus.chat_opened.connect(_on_chat_opened)

	danilo_collision_shape_2d.disabled = true
	player_danilo.animation_locked = true
	player_danilo.force_cannot_move = true
	animated_sprite_2d.play("sitting")

	Hud.phone_intro()
	add_notification(CHAT_ICON, "Chat", "2 missed calls from Mira")
	await get_tree().create_timer(1.0).timeout
	add_notification(CHAT_ICON, "Chat", "Wendy: Dan, you didn’t even inform me you were going home. We were worried, hindi ka sumasagot sa chats ko. Akala ko may nangyari na sayo")

	await get_tree().create_timer(1.0).timeout
	Hud.clear_objectives()
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	Hud.objective_intro_anim()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		match player_danilo.current_npc:
			"window_1":
				if not window_1_closed:
					window_1.region_rect = Rect2(0,0,32,34)
					window_area_1.queue_free()
					window_1_closed = true;
					window_closed.emit()
			"window_2":
				if not window_2_closed:
					window_2.region_rect = Rect2(0,0,32,34)
					window_area_2.queue_free()
					window_2_closed = true;
					window_closed.emit()
			"window_3":
				if not window_3_closed:
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


func _on_reply_finished() -> void:
	if replied_to_mira and replied_to_wendy:
		ObjectiveManager.complete_objective(scene_objectives[0]["ID"])
		shadow_appear()

func _on_wendy_calling() -> void:
	var lockscreen = Hud.get_node("Control/phone/MarginContainer")
	for node in lockscreen.get_children():
		node.visible = false

	var phone_call_instance = PHONE_INCOMING_CALL.instantiate()
	lockscreen.add_child(phone_call_instance)

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
	player_danilo.position = marker_2d.position
	player_danilo.force_cannot_move = false;
	player_danilo.animation_locked = false;
	player_danilo.last_direction = Vector2.DOWN;
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
	if window_1_closed and window_1_closed and window_3_closed:
		ObjectiveManager.complete_objective(scene_objectives[1]["ID"])
		shadow_figure_vanish()
		shock_sprite.queue_free()

func shadow_figure_vanish()->void:
	await get_tree().create_timer(3.0).timeout
	npc_shadowy_chaser.queue_free()
	
