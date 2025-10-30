extends Node2D

# ===================
# PRELOADS
# ===================
var A_4S_1: Resource
const DANILO_HOMETOWN = preload("res://scenes/game/act_4/scene_1/danilo_hometown.tscn")
const DANILO_HOUSE = preload("res://scenes/game/act_4/scene_1/danilo_house.tscn")
const HABULAN_AREA = preload("res://scenes/game/act_4/scene_1/habulan_area.tscn")
const DARK_FOREST = preload("res://scenes/game/act_4/scene_3/dark_forest.tscn")
const NARRATION_PANEL = preload("res://helpers/narration_panel.tscn")
const SCHED_ICON = preload("uid://d1ye4ylli8nca")

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
var ghost_gone_area: Area2D

var mateo_diary: StaticBody2D
var mateo_diary_area: Area2D
var marked_map_area: Area2D
var camera_original_position: Vector2

var dark_forest_way_area: Area2D
var hometown_way_area:Area2D
var danilo_house_area: Area2D
var back_to_dark_forest_area: Area2D

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
var ghost_gone_triggered := false
var can_interact_mateo_diary := false
var marked_map_triggered := false
var can_enter_danilo_house_area := false

var next_habulan_spawn := "habulan_area_step_point"

# ===================
# OBJECTIVES
# ===================
var scene_objectives = [
	{"ID": 1, "text": "Go outside"},
	{"ID": 2, "text": "Go to the marked spot in the map"},
	{"ID": 3, "text": "Pick up the notebook"},
	{"ID": 4, "text": "Go to the dark forest to explore more clues"},
	{"ID": 5, "text": "Go home and take medications"},
]

# ===================
# READY
# ===================
func _ready():
	_game_state_flow()
	_load_dialogue()
	_start_scene()
	
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_4/scene_1/a4s1_en.dialogue"
	else:
		path = "res://dialogues/act_4/scene_1/a4s1.dialogue"
	
	A_4S_1 = load(path)
	
func _game_state_flow() -> void:
	FlashlightManager.set_current_scene("act_4", "scene_1")
	FlashlightManager.disable_flashlights()

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
func _switch_to_danilo_hometown(from_where: String = "") -> void:
	await get_tree().process_frame
	switch_location(DANILO_HOMETOWN)
	
	if from_where == "house_door_step_2":
		print("✅ Resetting triggers after narration...")
		_reset_hometown_triggers(true)

	for area in current_location.get_tree().get_nodes_in_group("areas"):
		if area is Area2D:
			area.monitoring = false
			area.monitorable = false

	var spawn_marker: Node2D = null
	match from_where:
		"back_to_hometown":
			spawn_marker = current_location.get_node_or_null("danilo/y-sorted-objects/spawn_points/back_to_hometown_point")
		"house_door_step":
			spawn_marker = current_location.get_node_or_null("danilo/y-sorted-objects/spawn_points/house_door_step_point")
		"house_door_step_2":
			spawn_marker = current_location.get_node_or_null("danilo/y-sorted-objects/spawn_points/house_door_step_point2")
		_:
			spawn_marker = current_location.get_node_or_null("danilo/y-sorted-objects/spawn_points/back_to_hometown_point")

	if spawn_marker and player_danilo:
		player_danilo.global_position = spawn_marker.global_position

	if from_where == "house_door_step":
		_reset_danilo_house_area()
		ObjectiveManager.complete_objective(1)
		ObjectiveManager.add_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"])
	elif from_where == "house_door_step_2":
		await get_tree().process_frame
		_reset_danilo_house_area()
		Hud.show_objectives()
		ObjectiveManager.complete_objective(5)
		DialogueManager.show_dialogue_balloon(A_4S_1, "back_to_adventure")
		ObjectiveManager.add_objective(scene_objectives[3]["ID"], scene_objectives[3]["text"])

	if from_where == "back_to_hometown":
		player_danilo.last_direction = Vector2.RIGHT
		_reset_hometown_triggers()

func _switch_to_habulan_area(from_where: String = "") -> void:
	Hud.clear_objectives()
	Hud.hide_objectives()
	await get_tree().process_frame
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	switch_location(HABULAN_AREA)
	player_danilo.last_direction = Vector2.LEFT
	if from_where == "habulan_area_step_point":
		_trigger_shadowy_ghost_event()

	var spawn_marker: Node2D = null
	match from_where:
		"back_to_habulan_area":
			spawn_marker = current_location.get_node_or_null("danilo/y-sorted-objects/spawn_points/back_to_habulan_area")
		"habulan_area_step_point":
			spawn_marker = current_location.get_node_or_null("danilo/y-sorted-objects/spawn_points/habulan_area_step_point")
		_:
			spawn_marker = current_location.get_node_or_null("danilo/y-sorted-objects/spawn_points/habulan_area_step_point")

	if spawn_marker and player_danilo:
		player_danilo.global_position = spawn_marker.global_position

	for area in current_location.get_tree().get_nodes_in_group("areas"):
		if area is Area2D and area.name != "dark_forest_way":
			area.monitoring = false
			area.monitorable = false
			area.visible = false

	if from_where == "habulan_area_step_point":
		marked_map_area = current_location.get_node_or_null("area/marked_map")
		if marked_map_area:
			marked_map_area.visible = true
			marked_map_area.body_entered.connect(_on_marked_map_area_entered)

	if from_where == "back_to_habulan_area":
		_reset_habulan_triggers()
		Hud.show_objectives()
		ObjectiveManager.add_objective(scene_objectives[3]["ID"], scene_objectives[3]["text"])
		
	if dark_forest_way_area:
		var is_completed = false

		if "completed_objectives" in ObjectiveManager and ObjectiveManager.completed_objectives.has(3):
			is_completed = true

		if is_completed:
			dark_forest_way_area.monitoring = true
			dark_forest_way_area.monitorable = true
			dark_forest_way_area.visible = true
			if not dark_forest_way_area.is_connected("body_entered", Callable(self, "_on_dark_forest_way_area_entered")):
				dark_forest_way_area.body_entered.connect(_on_dark_forest_way_area_entered)
		else:
			dark_forest_way_area.monitoring = false
			dark_forest_way_area.monitorable = false
			dark_forest_way_area.visible = false


	if from_where == "back_to_habulan_area":
		if dark_forest_way_area:
			dark_forest_way_area.monitoring = true
			dark_forest_way_area.monitorable = true
			dark_forest_way_area.visible = true
			if not dark_forest_way_area.is_connected("body_entered", Callable(self, "_on_dark_forest_way_area_entered")):
				dark_forest_way_area.body_entered.connect(_on_dark_forest_way_area_entered)
		return
		
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
	ghost_gone_area = current_location.get_node_or_null("area/ghost_gone")
	marked_map_area = current_location.get_node_or_null("area/marked_map")
	dark_forest_way_area = current_location.get_node_or_null("area/dark_forest_way")
	hometown_way_area = current_location.get_node_or_null("area/hometown_way")
	danilo_house_area = current_location.get_node_or_null("danilo/y-sorted-objects/areas/danilo_house_area")
	
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
		
	if ghost_gone_area:
		ghost_gone_area.body_entered.connect(_on_ghost_gone_area_entered)
		ghost_gone_area.monitoring = true
		ghost_gone_area.monitorable = true
		
	if marked_map_area:
		marked_map_area.visible = false
		marked_map_area.monitoring = false
		marked_map_area.monitorable = false

	if dark_forest_way_area:
		dark_forest_way_area.visible = false
		dark_forest_way_area.monitoring = false
		dark_forest_way_area.monitorable = false

	if hometown_way_area:
		hometown_way_area.visible = false
		hometown_way_area.monitoring = false
		hometown_way_area.monitorable = false
		
	if danilo_house_area:
		danilo_house_area.monitoring = true
		danilo_house_area.monitorable = true
		danilo_house_area.body_entered.connect(_on_danilo_house_area_entered)
		danilo_house_area.body_exited.connect(_on_danilo_house_area_exited)

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

	var spawn_point = next_habulan_spawn

	if flashlight_dialogue_triggered or phone_flashlight_complained:
		_switch_to_habulan_area(spawn_point)
	else:
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
			ghost_anim.play("idle_down")

		for c in shadowy_ghost.get_children():
			if c is CollisionShape2D:
				c.disabled = true

		_start_ghost_flicker(shadowy_ghost)

	var anim_sprite_danilo: AnimatedSprite2D = player_danilo.get_node_or_null("AnimatedSprite2D")
	if anim_sprite_danilo:
		anim_sprite_danilo.animation = "flashlight_idle_left"
		anim_sprite_danilo.frame = 0

	player_can_move_backup = player_danilo.force_cannot_move
	player_danilo.force_cannot_move = true
	player_danilo.set_physics_process(false)

	shadowy_ghost_target = shadowy_ghost_gone2
	ghost_moving = true


func _on_ghost_spawn_2_area_entered(body: Node) -> void:
	if body != player_danilo:
		return
	if ghost_moving:
		return

	if ghost_spawn_2_area:
		ghost_spawn_2_area.body_entered.disconnect(_on_ghost_spawn_2_area_entered)
		ghost_spawn_2_area.monitoring = false
		ghost_spawn_2_area.monitorable = false

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

	var anim_sprite_danilo: AnimatedSprite2D = player_danilo.get_node_or_null("AnimatedSprite2D")
	if anim_sprite_danilo:
		anim_sprite_danilo.animation = "flashlight_idle_left"
		anim_sprite_danilo.frame = 0

	player_can_move_backup = player_danilo.force_cannot_move
	player_danilo.force_cannot_move = true
	player_danilo.set_physics_process(false)

	shadowy_ghost_target = shadowy_ghost2_gone
	ghost_moving = true

func _on_ghost_gone_area_entered(body: Node) -> void:
	if body != player_danilo:
		return
	if ghost_gone_triggered:
		return 

	ghost_gone_triggered = true

	if ghost_gone_area:
		ghost_gone_area.body_entered.disconnect(_on_ghost_gone_area_entered)
		ghost_gone_area.monitoring = false
		ghost_gone_area.monitorable = false

	DialogueManager.show_dialogue_balloon(A_4S_1, "ghost_gone")
	await DialogueManager.dialogue_ended
	Hud.clear_objectives()
	Hud.show_objectives()
	ObjectiveManager.add_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"])

	mateo_diary = current_location.get_node_or_null("danilo/y-sorted/StaticBody2D")
	if mateo_diary:
		mateo_diary.visible = true
		mateo_diary_area = mateo_diary.get_node_or_null("mateo_diary_area")
		if mateo_diary_area:
			mateo_diary_area.body_entered.connect(_on_mateo_diary_area_entered)
			mateo_diary_area.body_exited.connect(_on_mateo_diary_area_exited)
			
	marked_map_area = current_location.get_node_or_null("area/marked_map")
	if marked_map_area:
		marked_map_area.visible = true
		marked_map_area.monitoring = true
		marked_map_area.monitorable = true
		marked_map_area.body_entered.connect(_on_marked_map_area_entered)

func _on_marked_map_area_entered(body: Node) -> void:
	if body != player_danilo:
		return
	if marked_map_triggered:
		return

	marked_map_triggered = true

	if marked_map_area:
		marked_map_area.body_entered.disconnect(_on_marked_map_area_entered)

	ObjectiveManager.complete_objective(2)
	DialogueManager.show_dialogue_balloon(A_4S_1, "marked_map")

	player_can_move_backup = player_danilo.force_cannot_move
	player_danilo.force_cannot_move = true
	player_danilo.set_physics_process(false)

	var anim_sprite_danilo: AnimatedSprite2D = player_danilo.get_node_or_null("AnimatedSprite2D")
	if anim_sprite_danilo:
		anim_sprite_danilo.animation = "flashlight_idle_right"
		anim_sprite_danilo.frame = 0

	var player_camera: Camera2D = player_danilo.get_node_or_null("Camera2D")
	if player_camera:
		var camera_original_position = player_camera.position
		var tween = player_camera.create_tween()
		tween.tween_property(player_camera, "position", camera_original_position + Vector2(200,0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_interval(2.5)
		tween.tween_property(player_camera, "position", camera_original_position, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished

	player_danilo.force_cannot_move = player_can_move_backup
	player_danilo.set_physics_process(true)

	ObjectiveManager.add_objective(scene_objectives[2]["ID"], scene_objectives[2]["text"])

func _on_mateo_diary_area_entered(body: Node) -> void:
	if body == player_danilo:
		can_interact_mateo_diary = true
		if tip_interact:
			tip_interact.visible = true

func _on_mateo_diary_area_exited(body: Node) -> void:
	if body == player_danilo:
		can_interact_mateo_diary = false
		if tip_interact:
			tip_interact.visible = false

func _on_dark_forest_way_area_entered(body: Node2D) -> void:
	if body != player_danilo:
		return
	await get_tree().process_frame
	scene_1_done()

func _on_hometown_way_area_entered(body: Node2D) -> void:
	if body != player_danilo:
		return
	await get_tree().process_frame
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	_switch_to_danilo_hometown("back_to_hometown")
	
func _on_danilo_house_area_entered(body: Node) -> void:
	if body != player_danilo:
		return
	can_enter_danilo_house_area = true
	if tip_interact:
		tip_interact.visible = true

func _on_danilo_house_area_exited(body: Node) -> void:
	if body != player_danilo:
		return
	can_enter_danilo_house_area = false
	if tip_interact:
		tip_interact.visible = false

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
	elif can_interact_mateo_diary and Input.is_action_just_pressed("interact"):
		_mateo_diary_interacted()
	elif can_enter_danilo_house_area and Input.is_action_just_pressed("interact"):
		_danilo_house_area_interacted()

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
	_switch_to_danilo_hometown("house_door_step")

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

func _mateo_diary_interacted() -> void:
	if mateo_diary:
		mateo_diary.queue_free()
	if tip_interact:
		tip_interact.visible = false
	ObjectiveManager.complete_objective(3)
	DialogueManager.show_dialogue_balloon(A_4S_1, "picked_up_notebook")
	await DialogueManager.dialogue_ended
	
func _open_phone_notifications() -> void:
	Hud.get_node("Control/phone/MarginContainer/lock_screen/Panel/lock").disabled = true
	Hud.reset_phone_state()
	await get_tree().create_timer(1.0).timeout
	add_notification(SCHED_ICON, "Reminder", "Take Medication")
	DialogueManager.show_dialogue_balloon(A_4S_1, "take_meds_or_continue_looking")
	await get_tree().create_timer(1.2).timeout

func _on_take_meds_chosen() -> void:
	print("Player chose to take meds.")
	if hometown_way_area:
		hometown_way_area.visible = true
		hometown_way_area.monitoring = true
		hometown_way_area.monitorable = true

		var callable_hometown = Callable(self, "_on_hometown_way_area_entered")
		if hometown_way_area.is_connected("body_entered", callable_hometown):
			hometown_way_area.body_entered.disconnect(callable_hometown)
		hometown_way_area.body_entered.connect(callable_hometown)

		if player_danilo and hometown_way_area.get_overlapping_bodies().has(player_danilo):
			_on_hometown_way_area_entered(player_danilo)
			
	ObjectiveManager.add_objective(scene_objectives[4]["ID"], scene_objectives[4]["text"])

func _on_continue_looking_chosen() -> void:
	print("Player chose to continue looking.")
	if dark_forest_way_area:
		dark_forest_way_area.visible = true
		dark_forest_way_area.monitoring = true
		dark_forest_way_area.monitorable = true

		var callable_dark_forest = Callable(self, "_on_dark_forest_way_area_entered")
		if dark_forest_way_area.is_connected("body_entered", callable_dark_forest):
			dark_forest_way_area.body_entered.disconnect(callable_dark_forest)
		dark_forest_way_area.body_entered.connect(callable_dark_forest)

		if player_danilo and dark_forest_way_area.get_overlapping_bodies().has(player_danilo):
			_on_dark_forest_way_area_entered(player_danilo)

	ObjectiveManager.add_objective(scene_objectives[3]["ID"], scene_objectives[3]["text"])

func _danilo_house_area_interacted() -> void:
	can_enter_danilo_house_area = false
	if tip_interact:
		tip_interact.visible = false

	TransitionFade.transition()
	await SignalBus.on_transition_finished
	Hud.hide_objectives()
	Hud.clear_objectives()
	switch_location(NARRATION_PANEL)
	_reset_hometown_triggers()
	await get_tree().process_frame
	var lines = [
		"“I let the medicines settle for a moment.“",
		"“Somehow, feels like I made the right call...“"
	]
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	next_habulan_spawn = "back_to_habulan_area"
	_switch_to_danilo_hometown("house_door_step_2")

# ===================
# OTHERS
# ===================
func add_notification(image: Texture2D, app_name: String, notif_content: String) -> void:
	Hud.get_node("Control/phone/MarginContainer/lock_screen").add_notification(image, app_name, notif_content)
	
# Move ising to marker
func start_ising_move(target: Vector2) -> void:
	if not npc_lola_ising:
		return
	npc_lola_ising.visible = true
	ising_target_position = target
	ising_moving = true
	if anim_sprite:
		anim_sprite.play("walk_left")

# Ghost glitch effect
func _start_ghost_flicker(ghost: CharacterBody2D) -> void:
	var ghost_sprite = ghost.get_node_or_null("AnimatedSprite2D")
	if not ghost_sprite:
		return

	ghost_sprite.visible = true
	ghost_sprite.modulate.a = 0.0

	var tween = ghost.create_tween()
	var flicker_times = 4
	var duration = 0.1

	for i in range(flicker_times):
		tween.tween_property(ghost_sprite, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(ghost_sprite, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_LINEAR)

	tween.tween_property(ghost_sprite, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_LINEAR)

# Ghost event after going to habulan area
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

# ===================
# RESET TRIGGERS/MONITORING
# ===================
func _reset_hometown_triggers(reset_flashlight_only := false) -> void:
	if not reset_flashlight_only and to_habulan_area:
		to_habulan_area.monitoring = false
		to_habulan_area.monitorable = false
		to_habulan_area.visible = false

	if flashlight_determinant:
		flashlight_determinant.monitoring = false
		flashlight_determinant.monitorable = false
		flashlight_determinant.visible = false

func _reset_danilo_house_area() -> void:
	if danilo_house_area:
		danilo_house_area.monitoring = false
		danilo_house_area.monitorable = false
		danilo_house_area.visible = false

	if tip_interact:
		tip_interact.visible = false

func _reset_habulan_triggers() -> void:
	if ghost_spawn_1_area:
		ghost_spawn_1_area.monitoring = false
		ghost_spawn_1_area.monitorable = false
		ghost_spawn_1_area.visible = false

	if ghost_spawn_2_area:
		ghost_spawn_2_area.monitoring = false
		ghost_spawn_2_area.monitorable = false
		ghost_spawn_2_area.visible = false

	if ghost_gone_area:
		ghost_gone_area.monitoring = false
		ghost_gone_area.monitorable = false
		ghost_gone_area.visible = false

	if marked_map_area:
		marked_map_area.monitoring = false
		marked_map_area.monitorable = false
		marked_map_area.visible = false

	if tip_shocked:
		tip_shocked.visible = false

	var ghost_node = current_location.get_node_or_null("danilo/y-sorted/npc_shadowy_ghost")
	if ghost_node:
		ghost_node.visible = false
		ghost_moving = false
		for c in ghost_node.get_children():
			if c is CollisionShape2D:
				c.disabled = true

# ===================
# COMPLETE SCENE
# ===================
func scene_1_done() -> void:
	ObjectiveManager.complete_objective(4)
	Hud.hide_objectives()
	Hud.clear_objectives()
	SaveManager.game_save.current_act = "act_4"
	SaveManager.game_save.current_scene = "scene_1"
	SaveManager.save_game()
	GameState.save_game()
	print("ACT 4 SCENE 1 DONE")
	SignalBus.act_num_scene_num_done.emit(
		"act_4", 
		"scene_1", 
        "res://scenes/game/act_4/scene_2/act_4_scene_2.tscn"
	)
