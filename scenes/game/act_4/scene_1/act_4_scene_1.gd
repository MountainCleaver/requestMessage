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
var tip_shocked: Sprite2D
var shadowy_ghost: CharacterBody2D

# Areas
var door_area: Area2D
var karatula_area: Area2D
var to_habulan_area: Area2D
var flashlight_determinant: Area2D
var ghost_spawn_1_area: Area2D

var ising_walk_target: Marker2D
var ising_target_position := Vector2.ZERO
var ising_speed := 50.0

var shadowy_ghost_target: Marker2D
var shadowy_ghost_appear: Marker2D
var shadowy_ghost_gone2: Marker2D
var ghost_speed := 120.0
var ghost_spawn_2_area: Area2D
var shadowy_ghost2_appear: Marker2D
var shadowy_ghost2_gone: Marker2D
# ===================
# STATES & FLAGS
# ===================
var can_use_door := false
var door_interacted := false
var can_interact_signage := false
var signage_shown := false
var can_talk_to_ising := false
var flashlight_dialogue_triggered := false
var phone_flashlight_complained := false
var ghost_moving := false
var player_can_move_backup := true
var ising_moving := false
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
	_trigger_shadowy_ghost_event()

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
	tip_shocked = player_danilo.get_node_or_null("tip_shocked") if player_danilo else null
	tip_interact = player_danilo.get_node_or_null("tip_interact") if player_danilo else null
	npc_lola_ising = current_location.get_node_or_null("danilo/y-sorted-objects/npc_lola_ising")
	anim_sprite = npc_lola_ising.get_node_or_null("AnimatedSprite2D") if npc_lola_ising else null
	flashlight_node = current_location.get_node_or_null("explorer_hud/Flashlight")

	door_area = current_location.get_node_or_null("door_area")
	karatula_area = current_location.get_node_or_null("danilo/y-sorted-objects/areas/karatula_area")
	to_habulan_area = current_location.get_node_or_null("danilo/y-sorted-objects/areas/to_habulan_area")
	flashlight_determinant = current_location.get_node_or_null("flashlight_determinant")
	ising_walk_target = current_location.get_node_or_null("danilo/y-sorted-objects/spawn_points/ising_walk")
	ghost_spawn_1_area = current_location.get_node_or_null("area/ghost_spawn_1")
	shadowy_ghost_appear = current_location.get_node_or_null("spawn_points/shadowy_ghost_appear")
	shadowy_ghost_gone2 = current_location.get_node_or_null("spawn_points/shadowy_ghost_gone2")
	ghost_spawn_2_area = current_location.get_node_or_null("area/ghost_spawn_2")
	shadowy_ghost2_appear = current_location.get_node_or_null("spawn_points/shadowy_ghost_appear2")
	shadowy_ghost2_gone = current_location.get_node_or_null("spawn_points/shadowy_ghost_gone3")
	
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

	if ghost_spawn_1_area:
		ghost_spawn_1_area.body_entered.connect(_on_ghost_spawn_1_area_entered)
		
	if ghost_spawn_2_area:
		ghost_spawn_2_area.body_entered.connect(_on_ghost_spawn_2_area_entered)
		ghost_spawn_2_area.monitoring = true
		ghost_spawn_2_area.monitorable = true
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
	if body != player_danilo:
		return
		
	await get_tree().process_frame
	# Check if player has talked to Lola Ising
	if flashlight_dialogue_triggered:
		_switch_to_habulan_area()
	else:
		# Show dialogue balloon telling the player to talk to Lola Ising first
		DialogueManager.show_dialogue_balloon(A_4S_1, "talk_to_ising_first")
		await DialogueManager.dialogue_ended

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
		DialogueManager.show_dialogue_balloon(A_4S_1, "open_phone_flashlight")
		await DialogueManager.dialogue_ended
		ObjectiveManager.add_objective(666, "Open phone flashlight") 

	if flashlight_determinant:
		flashlight_determinant.set_deferred("monitoring", false)
		flashlight_determinant.set_deferred("monitorable", false)

func _on_ghost_spawn_1_area_entered(body: Node) -> void:
	if body != player_danilo:
		return
	if ghost_moving:
		return

	# Disconnect signal so it never triggers again
	if ghost_spawn_1_area:
		ghost_spawn_1_area.body_entered.disconnect(_on_ghost_spawn_1_area_entered)
		ghost_spawn_1_area.monitoring = false
		ghost_spawn_1_area.monitorable = false

	# Instantiate ghost
	if not shadowy_ghost:
		var ghost_scene = preload("res://scenes/characters/npc_shadowy_ghost.tscn")
		shadowy_ghost = ghost_scene.instantiate()
		current_location.add_child(shadowy_ghost)
		shadowy_ghost.global_position = shadowy_ghost_appear.global_position
		shadowy_ghost.visible = true

		var ghost_anim: AnimatedSprite2D = shadowy_ghost.get_node_or_null("AnimatedSprite2D")
		if ghost_anim:
			ghost_anim.play("idle")

		for c in shadowy_ghost.get_children():
			if c is CollisionShape2D:
				c.disabled = true

		_start_ghost_flicker(shadowy_ghost)

	# Freeze player
	var anim_sprite_danilo: AnimatedSprite2D = player_danilo.get_node_or_null("AnimatedSprite2D")
	if anim_sprite_danilo:
		anim_sprite_danilo.animation = "flashlight_idle_left"
		anim_sprite_danilo.frame = 0

	player_can_move_backup = player_danilo.force_cannot_move
	player_danilo.force_cannot_move = true
	player_danilo.set_physics_process(false)

	shadowy_ghost_target = shadowy_ghost_gone2
	ghost_moving = true

	
# ===================
# GHOST SPAWN 2
# ===================
func _on_ghost_spawn_2_area_entered(body: Node) -> void:
	if body != player_danilo:
		return
	if ghost_moving:
		return

	# Disconnect signal so it never triggers again
	if ghost_spawn_2_area:
		ghost_spawn_2_area.body_entered.disconnect(_on_ghost_spawn_2_area_entered)
		ghost_spawn_2_area.monitoring = false
		ghost_spawn_2_area.monitorable = false

	# Instantiate ghost
	if not shadowy_ghost:
		var ghost_scene = preload("res://scenes/characters/npc_shadowy_ghost.tscn")
		shadowy_ghost = ghost_scene.instantiate()
		current_location.add_child(shadowy_ghost)
		shadowy_ghost.global_position = shadowy_ghost2_appear.global_position
		shadowy_ghost.visible = true

		var ghost_anim: AnimatedSprite2D = shadowy_ghost.get_node_or_null("AnimatedSprite2D")
		if ghost_anim:
			ghost_anim.play("idle_down")

		for c in shadowy_ghost.get_children():
			if c is CollisionShape2D:
				c.disabled = true

		_start_ghost_flicker(shadowy_ghost)

	# Freeze player
	var anim_sprite_danilo: AnimatedSprite2D = player_danilo.get_node_or_null("AnimatedSprite2D")
	if anim_sprite_danilo:
		anim_sprite_danilo.animation = "flashlight_idle_left"
		anim_sprite_danilo.frame = 0

	player_can_move_backup = player_danilo.force_cannot_move
	player_danilo.force_cannot_move = true
	player_danilo.set_physics_process(false)

	shadowy_ghost_target = shadowy_ghost2_gone
	ghost_moving = true

		
# ----------------------
# Ghost glitch effect
# ----------------------
func _start_ghost_flicker(ghost: CharacterBody2D) -> void:
	var ghost_sprite = ghost.get_node_or_null("AnimatedSprite2D")
	if not ghost_sprite:
		return

	# Siguraduhin invisible muna
	ghost_sprite.visible = true
	ghost_sprite.modulate.a = 0.0

	# Create tween for flicker
	var tween = ghost.create_tween()
	var flicker_times = 4
	var duration = 0.1

	for i in range(flicker_times):
		tween.tween_property(ghost_sprite, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(ghost_sprite, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_LINEAR)

	# Last flicker makes ghost fully visible
	tween.tween_property(ghost_sprite, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_LINEAR)


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

	# Handle Ising movement
	if ising_moving and npc_lola_ising:
		var dir = (ising_target_position - npc_lola_ising.global_position).normalized()
		npc_lola_ising.global_position += dir * ising_speed * delta
		if npc_lola_ising.global_position.distance_to(ising_target_position) < 5:
			npc_lola_ising.global_position = ising_target_position
			ising_moving = false
			if anim_sprite:
				anim_sprite.play("idle_left")

	# Ghost movement
	if ghost_moving and shadowy_ghost and shadowy_ghost_target:
		var dir = (shadowy_ghost_target.global_position - shadowy_ghost.global_position).normalized()
		shadowy_ghost.global_position += dir * ghost_speed * delta

		if shadowy_ghost.global_position.distance_to(shadowy_ghost_target.global_position) < 5:
			ghost_moving = false
			var ghost_anim: AnimatedSprite2D = shadowy_ghost.get_node_or_null("AnimatedSprite2D")
			if ghost_anim:
				ghost_anim.stop()
			shadowy_ghost.queue_free()

			if tip_shocked:
				tip_shocked.visible = false

			player_danilo.force_cannot_move = player_can_move_backup
			player_danilo.set_physics_process(true)


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
	if flashlight_dialogue_triggered:
		return
	flashlight_dialogue_triggered = true
	can_talk_to_ising = false
	if tip_interact:
		tip_interact.visible = false

	DialogueManager.show_dialogue_balloon(A_4S_1, "ising_give_flashlight")
	await DialogueManager.dialogue_ended
	ObjectiveManager.complete_objective(999)

	FlashlightManager.unlock_real_flashlight()
	FlashlightManager.real_flashlight_enabled = true
	
	# Make the flashlight node in scene visible
	var flashlight_node = $explorer_hud/Flashlight
	if flashlight_node:
		flashlight_node.visible = true

func _on_phone_flashlight_enabled() -> void:
	if phone_flashlight_complained:
		return
	phone_flashlight_complained = true
	ObjectiveManager.complete_objective(666)
	DialogueManager.show_dialogue_balloon(A_4S_1, "complain_phone_flashlight")

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

# ===================
# SHADOWY GHOST EVENT
# ===================
func _trigger_shadowy_ghost_event() -> void:
	if not current_location or not player_danilo:
		return
	
	# Freeze player
	player_can_move_backup = player_danilo.force_cannot_move
	player_danilo.force_cannot_move = true
	player_danilo.set_physics_process(false)

	# Force flashlight idle animation
	var anim_sprite_danilo: AnimatedSprite2D = player_danilo.get_node_or_null("AnimatedSprite2D")
	if anim_sprite_danilo:
		anim_sprite_danilo.animation = "flashlight_idle_left"
		anim_sprite_danilo.frame = 0

	# Show shocked tip
	if tip_shocked:
		tip_shocked.visible = true

	DialogueManager.show_dialogue_balloon(A_4S_1, "danilo_saw_ghost")
	await DialogueManager.dialogue_ended

	shadowy_ghost = current_location.get_node_or_null("danilo/y-sorted/npc_shadowy_ghost")
	shadowy_ghost_target = current_location.get_node_or_null("spawn_points/shadowy_ghost_gone")
	if shadowy_ghost and shadowy_ghost_target:
		shadowy_ghost.visible = true
		var ghost_anim: AnimatedSprite2D = shadowy_ghost.get_node_or_null("AnimatedSprite2D")
		if ghost_anim:
			ghost_anim.play("walk")
		for c in shadowy_ghost.get_children():
			if c is CollisionShape2D:
				c.disabled = true
		ghost_moving = true
