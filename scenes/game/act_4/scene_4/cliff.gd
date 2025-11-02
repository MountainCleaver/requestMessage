extends Node2D

var A_4S_4: Resource

@onready var phone_trigger: Area2D = $phone_trigger
@onready var player_danilo: CharacterBody2D = $"y-sorted/player_danilo"
@onready var sfx_notif: AudioStreamPlayer = $SFX_NOTIF
@onready var cliff_portal: Area2D = $portal
@onready var diary_note: Area2D = $map/paper

var scene_objectives = [
	{"ID": 2, "text": "Find the last paper under the rocks"},
	{"ID": 3, "text": "Leave the cliff"}
]

# State flags
var unknown_sender_opened := false
var phone_showing := false
var lock_screen_active := false
var phone_main_active := false
var chat_open := false
var portal_unlocked := false
var portal_ready := false
var note_collected := false
var player_in_range := false

func _ready() -> void:
	print("A4S4: Scene ready")
	FlashlightManager.set_current_scene("act_4", "scene_4")
	FlashlightManager.enable_flashlight_by_cash()
	_game_state_flow()
	_load_dialogue()

	# Set up signals
	cliff_portal.body_entered.connect(_on_cliff_portal_entered)
	diary_note.body_entered.connect(_on_note_body_entered)
	diary_note.body_exited.connect(_on_note_body_exited)

	enable_phone_trigger()
	disable_portal_trigger() # 🔹 portal off muna

func _game_state_flow() -> void:
	ObjectiveManager.complete_objective(1)
	GameState.load_game()
	GameState.current_act = "act_4"
	GameState.current_scene = "scene_4"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()

	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	print("Scene objectives initialized")

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String = "res://dialogues/act_4/scene_4/a4s4.dialogue"
	if lang == "en":
		path = "res://dialogues/act_4/scene_4/a4s4_en.dialogue"
	A_4S_4 = load(path)
	print("Dialogue loaded:", path)

# PHONE =============================================

func enable_phone_trigger() -> void:
	print("Phone trigger enabled")
	phone_trigger.visible = true
	phone_trigger.monitoring = true
	phone_trigger.set_deferred("monitorable", true)

func disable_phone_trigger() -> void:
	print("Phone trigger disabled")
	phone_trigger.monitoring = false
	phone_trigger.set_deferred("monitorable", false)
	phone_trigger.visible = false

func _on_phone_trigger_body_entered(body: Node2D) -> void:
	print("Phone trigger entered by:", body.name)
	sfx_notif.play()
	if body.name != "player_danilo":
		return
	SignalBus.unknown_sender_unlocked = true
	phone_showing = true
	if not unknown_sender_opened:
		Hud.show_phone_with_unknown_sender()
		await get_tree().create_timer(1.0).timeout
		player_danilo.force_cannot_move = true
		_on_chat_opened("unknown_sender")

	disable_phone_trigger()

	player_danilo.force_cannot_move = false
	player_danilo.can_move = true
	player_danilo.can_interact = true

func _on_chat_opened(chat_name: String) -> void:
	if chat_name == "unknown_sender" and not unknown_sender_opened:
		unknown_sender_opened = true
		print("Chat opened: unknown sender")
		DialogueManager.show_dialogue_balloon(A_4S_4, "unknown_message")

# NOTE (merged from note.gd) ==========================

func _on_note_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		print("Player entered note area — Press [E] to read the paper")
		SignalBus.in_npc.emit("Press [E] to read the paper")

func _on_note_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		print("Player exited note area")
		SignalBus.out_npc.emit("clear")

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact") and not note_collected:
		SignalBus.out_npc.emit("clear")
		ObjectiveManager.complete_objective(scene_objectives[0]["ID"])
		if Hud.has_method("mark_objective_done"):
			Hud.mark_objective_done()
		print("Note collected! Showing dialogue...")
		DialogueManager.show_dialogue_balloon(A_4S_4, "after_found_paper")
		ObjectiveManager.add_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"])
		note_collected = true
		on_note_collected()
		diary_note.queue_free()

# PORTAL =============================================

func disable_portal_trigger() -> void:
	print("Portal trigger disabled (default)")
	cliff_portal.monitoring = false
	cliff_portal.set_deferred("monitorable", false)
	cliff_portal.visible = true

func enable_portal_trigger() -> void:
	print("Attempting to enable portal trigger...")
	cliff_portal.monitoring = true
	cliff_portal.set_deferred("monitorable", true)
	print("Portal unlocked! Monitoring:", cliff_portal.monitoring)
	portal_ready = false
	await get_tree().create_timer(0.5).timeout
	portal_ready = true
	print("Portal ready = true ✅")

func on_note_collected() -> void:
	print("NOTE COLLECTED — enabling portal...")
	portal_unlocked = true
	enable_portal_trigger()

func _on_cliff_portal_entered(body: Node) -> void:
	print("Portal body_entered triggered by:", body.name)

	if not body.is_in_group("player"):
		print("Ignored: not player")
		return
	if not portal_unlocked:
		print("Portal locked — paper not yet collected.")
		return
	if not portal_ready:
		print("Portal not ready yet.")
		return

	print("Teleporting from Cliff to Forest...")
	get_tree().set_meta("last_portal_name", cliff_portal.name)
	get_tree().set_meta("last_portal_position", cliff_portal.global_position)
	TransitionFade.transition()
	await get_tree().create_timer(0.15).timeout
	act_4_scene_4_done()

func act_4_scene_4_done() -> void:
	print("ACT 4 SCENE 4 DONE")
	Hud.hide_objectives()
	Hud.clear_objectives()
	SaveManager.game_save.current_act = "act_4"
	SaveManager.game_save.current_scene = "scene_4"
	GameState.save_game()
	SaveManager.save_game()

	SignalBus.act_num_scene_num_done.emit(
		"act_4", 
		"scene_4", 
		"res://scenes/game/act_5_title_scene.tscn"
	)
