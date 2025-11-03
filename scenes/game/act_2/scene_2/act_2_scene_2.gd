extends Node2D

# ===================
# PRELOADS
# ===================
var A_2S_2: Resource
const DANILO_ROOM = preload("res://scenes/game/act_2/scene_2/danilo_room.tscn")
const DANILO_NEIGHBORHOOD = preload("res://scenes/game/act_2/scene_2/danilo_neighborhood.tscn")
const NARRATION_PANEL = preload("res://helpers/narration_panel.tscn")

# ===================
# NODES
# ===================
@onready var locations: Node2D = $locations
var player_danilo: CharacterBody2D = null
var player_danilo2: CharacterBody2D = null
var animated_sprite_2d: AnimatedSprite2D = null
var tip_interact: Sprite2D = null
var bed_area: Area2D = null
var sleep_marker: Marker2D = null
var cabinet_area: Area2D = null
var door_area: Area2D = null
var jeep_area: Area2D = null
var current_location: Node = null

# ===================
# STATES & FLAGS
# ===================
var chat_open: bool = false
var inside_bed: bool = false
var can_interact: bool = false
var cabinet_interacted: bool = false
var door_interacted: bool = false
var can_use_door: bool = false
var can_use_jeep: bool = false
var jeep_interacted: bool = false
var mira_reply_shown: bool = false
var TL_reply_shown: bool = false

# ===================
# OBJECTIVES
# ===================
var scene_objectives = [
	{"ID": 1, "text": "Prepare your things from the cabinet for your hometown trip"},
	{"ID": 2, "text": "Send a message to Mira about your trip"},
	{"ID": 3, "text": "Send leave notice to TL/Workplace"},
	{"ID": 4, "text": "Go outside"},
	{"ID": 5, "text": "Ride the jeepney to Bus Terminal"}
]

# ===================
# READY
# ===================
func _ready():
	_game_state_flow()
	_load_dialogue()
	switch_location(NARRATION_PANEL)
	_start_scene()
	SignalBus.chat_message_sent.connect(_on_chat_message_sent)
	SignalBus.unknown_sender_unlocked = true
	SignalBus.unknown_sender_label_visible = false
	
	SignalBus.last_appointment_selected = "appointment_2"
	SignalBus.emit_signal("appointment_selected", "appointment_2")

func _game_state_flow() -> void:
	FlashlightManager.disable_flashlights()
	FlashlightManager.set_current_scene("act_2", "scene_2")
	GameState.load_game()
	GameState.current_act = "act_2"
	GameState.current_scene = "scene_2"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()
	
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_2/scene_2/a2s2_en.dialogue"
	else:
		path = "res://dialogues/act_2/scene_2/a2s2.dialogue"
	
	A_2S_2 = load(path)
	
# ===================
# START SCENE
# ===================
func _start_scene() -> void:
	await get_tree().process_frame

	var lines = ["The following morning..."]
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()

	TransitionFade.transition()
	await SignalBus.on_transition_finished
	switch_location(DANILO_ROOM)
	await get_tree().process_frame
	print("Returned to Danilo room")

	if player_danilo2:
		player_danilo2.visible = false

	if player_danilo and animated_sprite_2d:
		player_danilo.animation_locked = true
		player_danilo.can_move = false
		player_danilo.get_node("CollisionShape2D").disabled = true

		animated_sprite_2d.play("sleep")
		await get_tree().create_timer(3).timeout

		animated_sprite_2d.play("woken")
		await get_tree().create_timer(2).timeout

		player_danilo.visible = false
		if player_danilo2:
			player_danilo2.visible = true
			player_danilo2.global_position = player_danilo2.get_parent().to_global(player_danilo2.position)
			await get_tree().create_timer(1).timeout
			var anim = player_danilo2.get_node_or_null("AnimatedSprite2D")
			if anim:
				anim.play("idle_right")

		player_danilo.get_node("CollisionShape2D").disabled = false
		player_danilo2.animation_locked = false
		player_danilo2.can_move = true

	DialogueManager.show_dialogue_balloon(A_2S_2, "start")
	chat_open = false
	SignalBus.optional_chats_locked = false
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])

	if tip_interact:
		tip_interact.visible = false
	if bed_area:
		bed_area.monitoring = false

# ===================
# LOCATION HANDLER
# ===================
func switch_location(scene: PackedScene) -> void:
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()

	current_location = scene.instantiate()
	locations.add_child(current_location)

	player_danilo = current_location.get_node_or_null("player_danilo")
	player_danilo2 = current_location.get_node_or_null("player_danilo2")
	animated_sprite_2d = player_danilo.get_node_or_null("AnimatedSprite2D") if player_danilo else null
	tip_interact = player_danilo2.get_node_or_null("tip_interact") if player_danilo2 else null
	bed_area = current_location.get_node_or_null("bed_area")
	sleep_marker = current_location.get_node_or_null("sleep_marker")
	cabinet_area = current_location.get_node_or_null("cabinet_area")
	door_area = current_location.get_node_or_null("door_area")

	# === Jeep Area (child of AnimatedSprite2D jeep) ===
	var jeep_sprite = current_location.get_node_or_null("jeep") # AnimatedSprite2D node
	if jeep_sprite:
		jeep_area = jeep_sprite.get_node_or_null("jeep_area") # Area2D
		if jeep_area:
			jeep_area.body_entered.connect(_on_jeep_area_body_entered)
			jeep_area.body_exited.connect(_on_jeep_area_body_exited)

	# === Connect Cabinet Area Signals ===
	if cabinet_area:
		cabinet_area.body_entered.connect(_on_cabinet_area_body_entered)
		cabinet_area.body_exited.connect(_on_cabinet_area_body_exited)

	# === Connect Door Area Signals ===
	if door_area:
		door_area.monitoring = false 
		door_area.body_entered.connect(_on_door_area_body_entered)
		door_area.body_exited.connect(_on_door_area_body_exited)


# ===================
# CABINET AREA HANDLERS
# ===================
func _on_cabinet_area_body_entered(body):
	if body == player_danilo2 and not cabinet_interacted:
		can_interact = true
		if tip_interact:
			tip_interact.visible = true

func _on_cabinet_area_body_exited(body):
	if body == player_danilo2:
		can_interact = false
		if tip_interact:
			tip_interact.visible = false

# ===================
# DOOR AREA HANDLERS
# ===================
func _on_door_area_body_entered(body):
	if body == player_danilo2 and not door_interacted:
		can_use_door = true
		if tip_interact:
			tip_interact.visible = true

func _on_door_area_body_exited(body):
	if body == player_danilo2:
		can_use_door = false
		if tip_interact:
			tip_interact.visible = false

# ===================
# JEEP AREA HANDLERS
# ===================
func _on_jeep_area_body_entered(body):
	if body == player_danilo and not jeep_interacted:
		can_use_jeep = true
		if tip_interact:
			tip_interact.visible = true
		if player_danilo.has_method("show_tip"):
			player_danilo.show_tip("jeep")
		SignalBus.in_jeep_area.emit()

func _on_jeep_area_body_exited(body):
	if body == player_danilo:
		can_use_jeep = false
		if tip_interact:
			tip_interact.visible = false
		if player_danilo.has_method("hide_tip"):
			player_danilo.hide_tip("jeep")
		SignalBus.out_jeep_area.emit()

# ===================
# INPUT HANDLER
# ===================
func _process(_delta):
	if can_interact and not cabinet_interacted and Input.is_action_just_pressed("interact"):
		_cabinet_interacted()
	elif can_use_door and not door_interacted and Input.is_action_just_pressed("interact"):
		_door_interacted()
	elif can_use_jeep and Input.is_action_just_pressed("interact"):
		_jeep_interacted()  # no jeep_interacted check here

# ===================
# INTERACTION
# ===================
func _cabinet_interacted():
	cabinet_interacted = true
	can_interact = false
	if tip_interact:
		tip_interact.visible = false
	DialogueManager.show_dialogue_balloon(A_2S_2, "cabinet_clicked")
	_chat_with_mira()

func _door_interacted():
	door_interacted = true
	can_use_door = false
	if tip_interact:
		tip_interact.visible = false
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	_switch_to_danilo_neighborhood()

func _jeep_interacted():
	if tip_interact:
		tip_interact.visible = false
	DialogueManager.show_dialogue_balloon(A_2S_2, "sakay_jeep")

# ===================
# SWITCH LOCATION TO DANILO NEIGHBORHOOD
# ===================
func _switch_to_danilo_neighborhood() -> void:
	switch_location(DANILO_NEIGHBORHOOD)
	ObjectiveManager.complete_objective(4)
	ObjectiveManager.add_objective(scene_objectives[4]["ID"], scene_objectives[4]["text"])

# ===================
# CHAT HANDLERS
# ===================
func _chat_with_mira() -> void:
	await get_tree().create_timer(2).timeout
	ObjectiveManager.add_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"])
	DialogueManager.show_dialogue_balloon(A_2S_2, "chat_with_mira")

func _chat_with_TL() -> void:
	await get_tree().create_timer(1).timeout
	DialogueManager.show_dialogue_balloon(A_2S_2, "chat_with_TL")
	ObjectiveManager.add_objective(scene_objectives[2]["ID"], scene_objectives[2]["text"])

func _on_chat_message_sent(chat_name: String) -> void:
	chat_open = false
	SignalBus.optional_chats_locked = false
	if chat_name == "mira" and not mira_reply_shown:
		mira_reply_shown = true
		DialogueManager.show_dialogue_balloon(A_2S_2, "choice_danilo_1")
		await DialogueManager.dialogue_ended
		ObjectiveManager.complete_objective(2)
		await _chat_with_TL()  
	if chat_name == "group_chat" and not TL_reply_shown:
		TL_reply_shown = true
		DialogueManager.show_dialogue_balloon(A_2S_2, "choice_danilo_2")
		await DialogueManager.dialogue_ended
		await get_tree().create_timer(1).timeout
		Hud.clear_objectives()
		ObjectiveManager.add_objective(scene_objectives[3]["ID"], scene_objectives[3]["text"])
		DialogueManager.show_dialogue_balloon(A_2S_2, "go_outside")
		
		if door_area:
			door_area.monitoring = true

# ===================
# COMPLETE SCENE
# ===================
func scene_2_done() -> void:
	Hud.hide_objectives()
	Hud.clear_objectives()
	SaveManager.game_save.current_act = "act_2"
	SaveManager.game_save.current_scene = "scene_2"
	SaveManager.save_game()
	GameState.save_game()
	print("ACT 2 SCENE 2 DONE")
	SignalBus.act_num_scene_num_done.emit(
		"act_2", 
		"scene_2", 
        "res://scenes/game/act_2/scene_3/act_2_scene_3.tscn"
	)
