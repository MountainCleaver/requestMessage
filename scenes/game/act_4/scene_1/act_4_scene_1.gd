extends Node2D

# ===================
# PRELOADS
# ===================
const A_4S_1 = preload("res://dialogues/act_4/scene_1/a4s1.dialogue")
const DANILO_HOMETOWN = preload("res://scenes/game/act_4/scene_1/danilo_hometown.tscn")
const DANILO_HOUSE = preload("res://scenes/game/act_4/scene_1/danilo_house.tscn")
const HABULAN_AREA = preload("res://scenes/game/act_4/scene_1/habulan_area.tscn")
const DARK_FOREST = preload("res://scenes/game/act_4/scene_3/dark_forest.tscn")
const NARRATION_PANEL = preload("res://helpers/narration_panel.tscn")

# ===================
# NODES
# ===================
@onready var locations: Node2D = $locations
var player_danilo: CharacterBody2D
var tip_interact: Sprite2D
var current_location: Node
var npc_lola_ising: CharacterBody2D
var anim_sprite: AnimatedSprite2D
var flashlight_node: Node2D

# Areas
var door_area: Area2D
var karatula_area: Area2D
var to_habulan_area: Area2D

var ising_walk_target: Marker2D
var flashlight_determinant: Area2D

# ===================
# STATES & FLAGS
# ===================
var can_use_door := false
var door_interacted := false
var can_interact_signage := false
var signage_shown := false
var can_talk_to_ising := false
var flashlight_dialogue_triggered := false

# Movement flags for Ising
var ising_moving := false
var ising_target_position := Vector2.ZERO
var ising_speed := 50.0

# ===================
# OBJECTIVES
# ===================
var scene_objectives = [
	{"ID": 1, "text": "Go outside"},
	{"ID": 2, "text": "Go to the marked spot in the map"},
]

# ===================
# READY
# ===================
func _ready():
	_game_state_flow()
	_start_scene()

func _game_state_flow() -> void:
	FlashlightManager.set_current_scene("act_4", "scene_1")
	# Ensure it starts disabled
	FlashlightManager.real_flashlight_enabled = false
	FlashlightManager.phone_flashlight_enabled = false

	GameState.load_game()
	GameState.current_act = "act_4"
	GameState.current_scene = "scene_1"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()

# ===================
# START SCENE
# ===================
func _start_scene() -> void:
	await get_tree().process_frame
	switch_location(DANILO_HOUSE)
	Hud.show_objectives()
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])

	FlashlightManager.phone_flashlight_enabled_signal.connect(_on_phone_flashlight_enabled)
# ===================
# LOCATION SWITCHES
# ===================
func _switch_to_danilo_hometown() -> void:
	await get_tree().process_frame
	switch_location(DANILO_HOMETOWN)
	ObjectiveManager.complete_objective(1)
	ObjectiveManager.add_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"])

func _switch_to_habulan_area() -> void:
	Hud.clear_objectives()
	Hud.hide_objectives()
	await get_tree().process_frame
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	switch_location(HABULAN_AREA)

# ===================
# LOCATION HANDLER
# ===================
func switch_location(scene: PackedScene) -> void:
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()

	current_location = scene.instantiate()
	locations.add_child(current_location)
	
	player_danilo = current_location.get_node_or_null("danilo/y-sorted/player_danilo")
	if not player_danilo:
		player_danilo = current_location.get_node_or_null("danilo/y-sorted-objects/player_danilo")
		
	tip_interact = player_danilo.get_node_or_null("tip_interact") if player_danilo else null
	npc_lola_ising = current_location.get_node_or_null("danilo/y-sorted-objects/npc_lola_ising")
	anim_sprite = npc_lola_ising.get_node_or_null("AnimatedSprite2D") if npc_lola_ising else null
	flashlight_node = current_location.get_node_or_null("map_test/Flashlight")
	
	door_area = current_location.get_node_or_null("door_area")
	karatula_area = current_location.get_node_or_null("danilo/y-sorted-objects/areas/karatula_area")
	to_habulan_area = current_location.get_node_or_null("danilo/y-sorted-objects/areas/to_habulan_area")
	flashlight_determinant = current_location.get_node_or_null("flashlight_determinant")
	
	ising_walk_target = current_location.get_node_or_null("danilo/y-sorted-objects/spawn_points/ising_walk")
		
	if door_area:
		door_area.body_entered.connect(_on_door_area_body_entered)
		door_area.body_exited.connect(_on_door_area_body_exited)

	if karatula_area:
		karatula_area.body_entered.connect(_on_karatula_area_body_entered)
		karatula_area.body_exited.connect(_on_karatula_area_body_exited)
	
	if to_habulan_area:
		to_habulan_area.body_entered.connect(_on_to_habulan_area_body_entered)
	
	if flashlight_determinant:
		flashlight_determinant.body_entered.connect(_on_flashlight_determinant_body_entered)
		
	if npc_lola_ising:
		npc_lola_ising.visible = false

# ===================
# AREA HANDLERS
# ===================
func _on_door_area_body_entered(body):
	if body == player_danilo and not door_interacted:
		can_use_door = true
		if tip_interact:
			tip_interact.visible = true

func _on_door_area_body_exited(body):
	if body == player_danilo:
		can_use_door = false
		if tip_interact:
			tip_interact.visible = false

func _on_karatula_area_body_entered(body: Node2D) -> void:
	if body == player_danilo:
		player_danilo.can_interact = true
		player_danilo.current_npc = "signage"
		can_interact_signage = true
		if tip_interact:
			tip_interact.visible = true

func _on_karatula_area_body_exited(body: Node2D) -> void:
	if body == player_danilo:
		player_danilo.can_interact = false
		player_danilo.current_npc = ""
		can_interact_signage = false
		if tip_interact:
			tip_interact.visible = false

func _on_to_habulan_area_body_entered(body: Node2D) -> void:
	if body == player_danilo:
		await get_tree().process_frame
		_switch_to_habulan_area()

func _on_ising_interact_area_entered(body: Node2D) -> void:
	if body == player_danilo:
		can_talk_to_ising = true
		if tip_interact:
			tip_interact.visible = true

func _on_ising_interact_area_exited(body: Node2D) -> void:
	if body == player_danilo:
		can_talk_to_ising = false
		if tip_interact:
			tip_interact.visible = false
			
func _on_flashlight_determinant_body_entered(body: Node2D) -> void:
	if body != player_danilo:
		return

	if flashlight_dialogue_triggered:
		return

	if SaveManager.has_given_lola_ising_cash():
		print("Triggering Ising flashlight event.")

		player_danilo.force_cannot_move = true

		if npc_lola_ising and ising_walk_target:
			start_ising_move(ising_walk_target.global_position)

		DialogueManager.show_dialogue_balloon(A_4S_1, "ising_call_danilo")
		await DialogueManager.dialogue_ended

		player_danilo.force_cannot_move = false
		ObjectiveManager.add_objective(999, "Talk to Lola Ising")
		var ising_area = npc_lola_ising.get_node_or_null("lola_ising_area")
		if ising_area:
			ising_area.body_entered.connect(_on_ising_interact_area_entered)
			ising_area.body_exited.connect(_on_ising_interact_area_exited)

	else:
		print("Condition not met: 'di lalabas si Ising.")
		DialogueManager.show_dialogue_balloon(A_4S_1, "open_phone_flashlight")
		await DialogueManager.dialogue_ended
		ObjectiveManager.add_objective(666, "Open phone flashlight") 

	if flashlight_determinant:
		flashlight_determinant.set_deferred("monitoring", false)
		flashlight_determinant.set_deferred("monitorable", false)
# ===================
# INPUT HANDLER
# ===================
func _process(delta):
	if can_use_door and not door_interacted and Input.is_action_just_pressed("interact"):
		_door_interacted()
	elif can_interact_signage and Input.is_action_just_pressed("interact"):
		_karatula_interacted()
	elif can_talk_to_ising and Input.is_action_just_pressed("interact"):
		_ising_interacted()

	# Handle Ising smooth movement
	if ising_moving and npc_lola_ising:
		var direction = (ising_target_position - npc_lola_ising.global_position).normalized()
		npc_lola_ising.global_position += direction * ising_speed * delta

		if npc_lola_ising.global_position.distance_to(ising_target_position) < 5:
			npc_lola_ising.global_position = ising_target_position
			ising_moving = false
			if anim_sprite:
				anim_sprite.play("idle_left")
			print("Lola Ising reached the marker.")

# ===================
# INTERACTIONS
# ===================
func _door_interacted():
	door_interacted = true
	can_use_door = false
	if tip_interact:
		tip_interact.visible = false
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	_switch_to_danilo_hometown()

func _karatula_interacted():
	signage_shown = !signage_shown
	
	if signage_shown:
		tip_interact.visible = false
		player_danilo.last_direction = Vector2.UP
		Hud.add_popup_image("res://assets/HUD/signage_laruan.png")
		Hud._toggle_popup()
		player_danilo.force_cannot_move = Hud.popup_showing
	else:
		tip_interact.visible = true
		Hud._toggle_popup()
		player_danilo.force_cannot_move = false

func _ising_interacted() -> void:
	if not flashlight_dialogue_triggered:
		flashlight_dialogue_triggered = true
		can_talk_to_ising = false
		if tip_interact:
			tip_interact.visible = false

		# Dialogue
		DialogueManager.show_dialogue_balloon(A_4S_1, "ising_give_flashlight")
		await DialogueManager.dialogue_ended
		ObjectiveManager.complete_objective(999)

		# Unlock real flashlight
		FlashlightManager.unlock_real_flashlight()

		# Force it enabled for current scene
		FlashlightManager.real_flashlight_enabled = true

		print("[FlashlightManager] Real flashlight ENABLED after Lola Ising dialogue.")

		# Make the flashlight node in scene visible
		var flashlight_node = $map_test/Flashlight
		if flashlight_node:
			flashlight_node.visible = true
			print("Flashlight is now visible in scene!")

func _on_phone_flashlight_enabled() -> void:
	ObjectiveManager.complete_objective(666)

# ===================
# ISING MOVEMENT
# ===================
func start_ising_move(target: Vector2) -> void:
	if not npc_lola_ising:
		return
	npc_lola_ising.visible = true
	ising_target_position = target
	ising_moving = true
	if anim_sprite:
		anim_sprite.play("walk_left")
