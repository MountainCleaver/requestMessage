extends Node2D 

# ===================
# PRELOADS
# ===================
var A_4S_3: Resource
const DARK_FOREST = preload("res://scenes/game/act_4/scene_3/dark_forest.tscn")
const CHAPEL_EXTERIOR = preload("res://scenes/game/act_4/scene_3/chapel_exterior.tscn")
const CHAPEL_INTERIOR = preload("res://scenes/game/act_4/scene_3/chapel_interior.tscn")
const NARRATION_PANEL = preload("res://helpers/narration_panel.tscn")

@onready var sfx_light : AudioStreamPlayer = $SFX_LIGHTER
@onready var bgm_chapel: AudioStreamPlayer = $BGMChapel
@onready var bgm_appear: AudioStreamPlayer = $BGM_appear
@onready var sfx_creepy: AudioStreamPlayer = $SFX_Creepywind
@onready var sfx_appear: AudioStreamPlayer = $SFX_appear
@onready var explorer_hud: CanvasLayer = $explorer_hud

# ===================
# NODES
# ===================
@onready var locations: Node2D = $locations
var player_danilo: CharacterBody2D
var tip_interact: Sprite2D
var current_location: Node

# Areas
var dark_forest_entrance_area: Area2D
var door_area: Area2D
var before_door_area: Area2D
var lighter_area: Area2D
var lighter_node: Node2D
var big_candle_area: Area2D
var exit_area: Area2D
var exit_chapel_exterior_area: Area2D
var signage: Area2D
var dizzy_overlay: ColorRect

# Explore triggers
var cabinet_1_trigger: Area2D
var cabinet_2_trigger: Area2D
var mateo_things_trigger: Area2D
var candle_trigger: Area2D

# ===================
# STATES & FLAGS
# ===================
var can_use_door := false
var can_pick_lighter := false
var lighter_picked := false
var door_interacted := false
var dialogue_triggered := false
var signage_dialogue_shown := false

var can_exit_chapel := false
var exit_chapel_exterior_triggered := false

var can_interact_candle := false
var candle_ignited := false
var lit_candles := {}

var candle_sequence := []  
var current_step := 0
var sequence_fixed := false

var candle_colors = {
	1: "R",
	2: "O",
	3: "Y",
	4: "G",
	5: "B",
	6: "V"
}

var explore_objective_id := 3
var explore_goal := 4
var explored_spots := {}
var total_explore_spots := 4

var cabinet_1_area: Area2D
var cabinet_2_area: Area2D
var can_interact_cabinet := false
var current_cabinet := ""
var cabinets_opened := {"cabinet_1": false, "cabinet_2": false}
var dizzy_duration := 1.5
var dizzy_timer: Timer = null

# ===================
# OBJECTIVES
# ===================
var scene_objectives = [
	{"ID": 1, "text": "Go to the south side of the dark forest"},
	{"ID": 2, "text": "Find the hidden path"},
	{"ID": 3, "text": "Explore the area"},
	{"ID": 4, "text": "Light up the big candle at the center"},
	{"ID": 5, "text": "Light up the remaining candles"},
	{"ID": 6, "text": "Check the old cabinet"},
	{"ID": 7, "text": "Leave the old chapel"},
	{"ID": 8, "text": "Return to the dark forest and head to the last location"}
]

# ===================
# READY
# ===================
func _ready():
	_game_state_flow()
	_load_dialogue()
	switch_location(NARRATION_PANEL)
	_start_scene()
	SignalBus.unknown_sender_unlocked = true
	SignalBus.unknown_sender_label_visible = false
	_start_dizzy_timer() 
	
func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_4/scene_3/a4s3_en.dialogue"
	else:
		path = "res://dialogues/act_4/scene_3/a4s3.dialogue"
	
	A_4S_3 = load(path)
	
func _game_state_flow() -> void:
	FlashlightManager.set_current_scene("act_4", "scene_3")
	FlashlightManager.enable_flashlight_by_cash()
	GameState.load_game()
	GameState.current_act = "act_4"
	GameState.current_scene = "scene_3"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()

# ===================
# START SCENE
# ===================
func _start_scene() -> void:
	await get_tree().process_frame
	var lines = [
		"The trees are closer than before.",
		"Were they always this close?"
	]
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	_switch_to_dark_forest()

func _switch_to_dark_forest() -> void:
	await get_tree().process_frame
	switch_location(DARK_FOREST)
	explorer_hud.show_current_location(3)
	_trigger_dizzy_effect()
	player_danilo.last_direction = Vector2.RIGHT
	Hud.show_objectives()
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])

func _on_dark_forest_entrance_entered(body: Node) -> void:
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	if body == player_danilo:
		ObjectiveManager.complete_objective(1)
		_switch_to_chapel_exterior(false)


func _switch_to_chapel_exterior(from_chapel: bool) -> void:
	await get_tree().process_frame
	switch_location(CHAPEL_EXTERIOR)
	explorer_hud.show_current_location(5)

	var spawn_node: Node2D = null
	if from_chapel:
		spawn_node = current_location.get_node_or_null("spawn_chapel_exit")
	else:
		spawn_node = current_location.get_node_or_null("spawn_dark_forest")

	if spawn_node and player_danilo:
		player_danilo.global_position = spawn_node.global_position

	if from_chapel:
		_trigger_dizzy_effect()
		ObjectiveManager.complete_objective(7)
		DialogueManager.show_dialogue_balloon(A_4S_3, "back_to_dark_forest")
		await DialogueManager.dialogue_ended
		ObjectiveManager.add_objective(scene_objectives[7]["ID"], scene_objectives[7]["text"])

		exit_chapel_exterior_area = current_location.get_node_or_null("exit_chapel_exterior_area")
		if exit_chapel_exterior_area:
			exit_chapel_exterior_area.monitoring = true
			exit_chapel_exterior_area.visible = true
			exit_chapel_exterior_area.body_entered.connect(_on_exit_chapel_exterior_entered)

	else:
		_trigger_dizzy_effect()
		ObjectiveManager.add_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"])

func _switch_to_chapel_interior() -> void:
	bgm_chapel.play()
	Hud.clear_objectives()
	Hud.hide_objectives()
	switch_location(CHAPEL_INTERIOR)
	explorer_hud.show_current_location(5)
	_trigger_dizzy_effect()
	player_danilo.last_direction = Vector2.UP
	await get_tree().process_frame
	DialogueManager.show_dialogue_balloon(A_4S_3, "exploration_chat")
	await DialogueManager.dialogue_ended
	Hud.phone_outro()
	await get_tree().create_timer(1).timeout
	Hud.show_objectives()
	ObjectiveManager.add_progress_objective(explore_objective_id, "Explore the place", explore_goal)

func _setup_dark_forest_signage():
	signage = current_location.get_node_or_null("y-sorted/decorations/signage")

	if signage:
		signage.body_entered.connect(_on_signage_body_entered)
		signage.body_exited.connect(_on_signage_body_exited)
		print("Signage connected in Dark Forest")

# ===================
# LOCATION HANDLER
# ===================
func switch_location(scene: PackedScene) -> void:
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()

	current_location = scene.instantiate()
	locations.add_child(current_location)

	player_danilo = current_location.get_node("y-sorted/player_danilo")
	tip_interact = player_danilo.get_node_or_null("tip_interact") if player_danilo else null

	door_area = current_location.get_node_or_null("door_area")
	before_door_area = current_location.get_node_or_null("before_door_area")
	lighter_area = current_location.get_node_or_null("map/lighter/lighter_area")
	lighter_node = current_location.get_node_or_null("map/lighter")
	big_candle_area = current_location.get_node_or_null("map/candle/big_candle/big_candle_area")

	cabinet_1_trigger = current_location.get_node_or_null("y-sorted/cabinet_1/cabinet_1_trigger")
	cabinet_2_trigger = current_location.get_node_or_null("y-sorted/cabinet_2/cabinet_2_trigger")
	mateo_things_trigger = current_location.get_node_or_null("interactable/mateo_things")
	candle_trigger = current_location.get_node_or_null("map/candle/big_candle/candle_trigger")
	
	cabinet_1_area = current_location.get_node_or_null("y-sorted/cabinet_1/cabinet_1_area")
	cabinet_2_area = current_location.get_node_or_null("y-sorted/cabinet_2/cabinet_2_area")

	dizzy_overlay = current_location.get_node_or_null("ColorRect")
	
	if dizzy_overlay:
		dizzy_overlay.visible = false
	if scene == DARK_FOREST:
		dark_forest_entrance_area = current_location.get_node_or_null("entrance")
		_setup_dark_forest_signage()
	if dark_forest_entrance_area:
		dark_forest_entrance_area.body_entered.connect(_on_dark_forest_entrance_entered)
	if door_area:
		door_area.body_entered.connect(_on_door_area_body_entered)
		door_area.body_exited.connect(_on_door_area_body_exited)
	if before_door_area:
		before_door_area.body_entered.connect(_on_before_door_area_body_entered)
	if lighter_area:
		lighter_area.body_entered.connect(_on_lighter_area_body_entered)
		lighter_area.body_exited.connect(_on_lighter_area_body_exited)
	if big_candle_area:
		big_candle_area.body_entered.connect(_on_big_candle_area_body_entered)
		big_candle_area.body_exited.connect(_on_big_candle_area_body_exited)
	if cabinet_1_trigger:
		cabinet_1_trigger.body_entered.connect(_on_explore_triggered.bind("cabinet"))
	if cabinet_2_trigger:
		cabinet_2_trigger.body_entered.connect(_on_explore_triggered.bind("cabinet"))
	if mateo_things_trigger:
		mateo_things_trigger.body_entered.connect(_on_explore_triggered.bind("mateo_things"))
	if candle_trigger:
		candle_trigger.body_entered.connect(_on_explore_triggered.bind("candle"))

# ===================
# AREA HANDLERS
# ===================
func _on_signage_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	player_danilo.can_interact = true
	player_danilo.current_npc = "signage"
	if tip_interact:
		tip_interact.visible = true

func _on_signage_body_exited(body: Node2D) -> void:
	if body.name != "player_danilo":
		return
	player_danilo.can_interact = false
	player_danilo.current_npc = ""
	if tip_interact:
		tip_interact.visible = false
	
func _on_before_door_area_body_entered(body):
	if body == player_danilo and not dialogue_triggered:
		dialogue_triggered = true
		player_danilo.set_physics_process(false)
		ObjectiveManager.complete_objective(2)
		DialogueManager.show_dialogue_balloon(A_4S_3, "start")
		player_danilo.set_physics_process(true)

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

func _on_lighter_area_body_entered(body):
	if body == player_danilo and not lighter_picked:
		can_pick_lighter = true
		if tip_interact:
			tip_interact.visible = true

func _on_lighter_area_body_exited(body):
	if body == player_danilo:
		can_pick_lighter = false
		if tip_interact:
			tip_interact.visible = false

func _on_big_candle_area_body_entered(body):
	if body == player_danilo and explored_spots.size() >= total_explore_spots and not candle_ignited:
		can_interact_candle = true
		if tip_interact:
			tip_interact.visible = true

func _on_big_candle_area_body_exited(body):
	if body == player_danilo:
		can_interact_candle = false
		if tip_interact:
			tip_interact.visible = false

# ===================
# EXPLORE LOGIC
# ===================
func _on_explore_triggered(body, spot_name: String):
	if body != player_danilo:
		return
	if explored_spots.has(spot_name):
		return

	explored_spots[spot_name] = true
	ObjectiveManager.update_progress(explore_objective_id)

	match spot_name:
		"cabinet":
			DialogueManager.show_dialogue_balloon(A_4S_3, "explore_cabinet")
			await DialogueManager.dialogue_ended

		"mateo_things":
			DialogueManager.show_dialogue_balloon(A_4S_3, "explore_mateo_things")
			await DialogueManager.dialogue_ended

		"candle":
			DialogueManager.show_dialogue_balloon(A_4S_3, "explore_candle")
			await DialogueManager.dialogue_ended

	if explored_spots.size() >= total_explore_spots:
		ObjectiveManager.complete_objective(explore_objective_id)
		await get_tree().create_timer(1.0).timeout
		Hud.clear_objectives()
		DialogueManager.show_dialogue_balloon(A_4S_3, "after_explore_all")


# ===================
# INPUT HANDLER
# ===================
func _process(_delta):
	# Door interaction
	if can_use_door and not door_interacted and Input.is_action_just_pressed("interact"):
		_door_interacted()
	
	# Lighter pickup interaction
	if can_pick_lighter and not lighter_picked and Input.is_action_just_pressed("interact"):
		_on_lighter_picked()
	
	# Candle interaction
	if can_interact_candle and Input.is_action_just_pressed("interact"):
		can_interact_candle = false
		var current_candle = current_location.get_meta("current_candle")
		if current_candle != null:
			_light_small_candle(current_candle)
		elif not candle_ignited:
			_on_candle_interacted()
	
	# Cabinet interaction 
	if can_interact_cabinet and current_cabinet != "" and Input.is_action_just_pressed("interact"):
		_on_cabinet_interacted(current_cabinet)

	# Signage interaction
	if Input.is_action_just_pressed("interact") and player_danilo.can_interact and player_danilo.current_npc == "signage":
		player_danilo.last_direction = Vector2.UP
		Hud.add_popup_image("res://assets/HUD/signage_darkforest.png")
		Hud._toggle_popup()
		player_danilo.force_cannot_move = Hud.popup_showing

		if not signage_dialogue_shown:
			signage_dialogue_shown = true
			await get_tree().create_timer(0.5).timeout
			DialogueManager.show_dialogue_balloon(A_4S_3, "signage")
			
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
	_switch_to_chapel_interior()

func _on_lighter_picked():
	lighter_picked = true
	can_pick_lighter = false
	if tip_interact:
		tip_interact.visible = false
	if lighter_node:
		lighter_node.queue_free()
	DialogueManager.show_dialogue_balloon(A_4S_3, "lighter_found")
	await DialogueManager.dialogue_ended
	if not explored_spots.has("lighter"):
		explored_spots["lighter"] = true
		ObjectiveManager.update_progress(explore_objective_id)
	if explored_spots.size() >= total_explore_spots:
		ObjectiveManager.complete_objective(explore_objective_id)
		await get_tree().create_timer(1).timeout
		DialogueManager.show_dialogue_balloon(A_4S_3, "after_explore_all")

func _on_candle_interacted():
	candle_ignited = true
	can_interact_candle = false
	if tip_interact:
		tip_interact.visible = false

	var candle_sprite: Sprite2D = current_location.get_node("map/candle/big_candle/candle")
	if candle_sprite:
		sfx_light.play()
		candle_sprite.region_enabled = true
		candle_sprite.region_rect = Rect2(21, 0, 20.8, 29)

	var candle_light: PointLight2D = current_location.get_node("map/candle/big_candle/PointLight2D")
	if candle_light:
		candle_light.visible = true
		var tween = create_tween()
		candle_light.texture_scale = 0.5 
		tween.tween_property(candle_light, "texture_scale", 1.7, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	ObjectiveManager.complete_objective(4)
	Hud.show_phone_with_unknown_sender()
	DialogueManager.show_dialogue_balloon(A_4S_3, "candle_ignited")
	await DialogueManager.dialogue_ended


	var total_candles := 6
	ObjectiveManager.add_progress_objective(scene_objectives[4]["ID"], "Light up the remaining candles", total_candles)

	for i in range(1, 7):
		var area = current_location.get_node_or_null("map/candle/candle_%d/candle_%d_area" % [i, i])
		if area:
			area.visible = true
			area.monitoring = true
			area.body_entered.connect(_on_small_candle_area_entered.bind(i))
			area.body_exited.connect(_on_small_candle_area_exited.bind(i))
		var light = current_location.get_node_or_null("map/candle/candle_%d/PointLight2D" % i)
		if light:
			light.visible = false
		var sprite = current_location.get_node_or_null("map/candle/candle_%d/candle" % i)
		if sprite:
			sprite.region_rect = Rect2(0, 0, 9.6, 20)

func _on_cabinet_interacted(cabinet_name: String) -> void:
	can_interact_cabinet = false
	if tip_interact:
		tip_interact.visible = false

	match cabinet_name:
		"cabinet_1":
			DialogueManager.show_dialogue_balloon(A_4S_3, "wrong_old_cabinet")
		"cabinet_2":
			DialogueManager.show_dialogue_balloon(A_4S_3, "correct_old_cabinet")
	
	cabinets_opened[cabinet_name] = true

	if cabinets_opened["cabinet_1"] and cabinets_opened["cabinet_2"]:
		ObjectiveManager.complete_objective(6)
		await DialogueManager.dialogue_ended
		await get_tree().create_timer(2.0).timeout
		DialogueManager.show_dialogue_balloon(A_4S_3, "after_cabinets_dialogue")
		await DialogueManager.dialogue_ended

		Hud.clear_objectives()
		_on_leave_chapel_interior()
		
		if tip_interact:
			tip_interact.visible = false
		if cabinet_1_area:
			cabinet_1_area.monitoring = false
		if cabinet_2_area:
			cabinet_2_area.monitoring = false


# ===================
# SMALL CANDLE LOGIC
# ===================
func _on_small_candle_area_entered(body, index: int) -> void:
	if body == player_danilo and not lit_candles.has(index):
		can_interact_candle = true
		if tip_interact:
			tip_interact.visible = true
		current_location.set_meta("current_candle", index)

func _on_small_candle_area_exited(body, index: int) -> void:
	if body == player_danilo:
		can_interact_candle = false
		if tip_interact:
			tip_interact.visible = false
		current_location.set_meta("current_candle", null)

func _light_small_candle(index: int) -> void:
	if not sequence_fixed:
		_set_first_candle(index)
		return

	if index != candle_sequence[current_step]:
		tip_interact.visible = false
		_handle_wrong_candle_progress()
		return

	_light_candle_visual(index)
	current_step += 1
	ObjectiveManager.update_progress(scene_objectives[4]["ID"])

	if current_step >= candle_sequence.size():
		ObjectiveManager.complete_objective(scene_objectives[4]["ID"])
		await get_tree().create_timer(0.8).timeout
		DialogueManager.show_dialogue_balloon(A_4S_3, "all_candles_lit_up")
		Achievements.unlock_achievement(4)
		
		var sfx := AudioStreamPlayer.new()
		sfx.stream = load("res://sound/steel-chain-hard-clicking-89389.mp3")
		add_child(sfx)
		sfx.play()

		for i in range(1, 7):
			var light = current_location.get_node_or_null("map/candle/candle_%d/PointLight2D" % i)
			if light:
				var tween := create_tween()
				tween.tween_property(light, "texture_scale", 5.30, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				await get_tree().create_timer(0.2).timeout

		await get_tree().create_timer(2.0).timeout
		if sfx:
			sfx.queue_free()
		
		var cabinet1_sprite: Sprite2D = current_location.get_node_or_null("y-sorted/cabinet_1/cabinet")
		var cabinet2_sprite: Sprite2D = current_location.get_node_or_null("y-sorted/cabinet_2/cabinet")

		if cabinet1_sprite:
			cabinet1_sprite.region_enabled = true
			cabinet1_sprite.region_rect = Rect2(33, 0.847, 30.0, 32.195)
		if cabinet2_sprite:
			cabinet2_sprite.region_enabled = true
			cabinet2_sprite.region_rect = Rect2(33, 0.847, 30.0, 32.195)
			
		ObjectiveManager.add_objective(scene_objectives[5]["ID"], scene_objectives[5]["text"])
		_enable_cabinet_areas()

func _set_first_candle(index: int) -> void:
	candle_sequence = [index]
	var remaining := [1, 2, 3, 4, 5, 6]
	remaining.erase(index)
	remaining.shuffle()
	candle_sequence += remaining
	sequence_fixed = true
	current_step = 1
	print("Chosen sequence:")
	for i in range(candle_sequence.size()):
		print("%s-%d" % [candle_colors[candle_sequence[i]], i])

	_light_candle_visual(index)
	ObjectiveManager.update_progress(scene_objectives[4]["ID"])

func _handle_wrong_candle_progress() -> void:
	print("Wrong candle! Progress reset, same sequence remains.")
	DialogueManager.show_dialogue_balloon(A_4S_3, "wrong_candle")
	await DialogueManager.dialogue_ended
	_reset_candle_progress()

func _reset_candle_progress() -> void:
	for i in lit_candles.keys():
		var sprite = current_location.get_node_or_null("map/candle/candle_%d/candle" % i)
		var light = current_location.get_node_or_null("map/candle/candle_%d/PointLight2D" % i)
		if sprite:
			sprite.region_rect = Rect2(0, 0, 9.6, 20)
		if light:
			light.visible = false
	lit_candles.clear()
	current_step = 0
	ObjectiveManager.reset_progress(scene_objectives[4]["ID"])

func _light_candle_visual(index: int) -> void:
	sfx_light.play()
	var sprite = current_location.get_node_or_null("map/candle/candle_%d/candle" % index)
	var light = current_location.get_node_or_null("map/candle/candle_%d/PointLight2D" % index)
	
	if sprite:
		sprite.region_rect = Rect2(9, 0, 9, 20)

	if light:
		light.visible = true
		light.texture_scale = 0.5 
		var tween := create_tween()
		tween.tween_property(light, "texture_scale", 1.95, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	lit_candles[index] = true
	if tip_interact:
		tip_interact.visible = false


func _enable_cabinet_areas():
	if cabinet_1_area:
		cabinet_1_area.monitoring = true
		cabinet_1_area.visible = true
		cabinet_1_area.body_entered.connect(_on_cabinet_area_entered.bind("cabinet_1"))
		cabinet_1_area.body_exited.connect(_on_cabinet_area_exited)
	if cabinet_2_area:
		cabinet_2_area.monitoring = true
		cabinet_2_area.visible = true
		cabinet_2_area.body_entered.connect(_on_cabinet_area_entered.bind("cabinet_2"))
		cabinet_2_area.body_exited.connect(_on_cabinet_area_exited)
		
func _on_cabinet_area_entered(body, cabinet_name: String):
	if body == player_danilo:
		can_interact_cabinet = true
		current_cabinet = cabinet_name
		if tip_interact:
			tip_interact.visible = true

func _on_cabinet_area_exited(body):
	if body == player_danilo:
		can_interact_cabinet = false
		current_cabinet = ""
		if tip_interact:
			tip_interact.visible = false

# ===================
# CHAPEL EXIT & CANDLE FLICKER 
# ===================
var candle_off_area: Area2D
var candle_off_area_triggered := false 
var tip_shocked: Sprite2D 
var npc_ghost: Node2D
var ghost_move_timer: Timer

func _on_leave_chapel_interior() -> void:
	ObjectiveManager.add_objective(scene_objectives[6]["ID"], scene_objectives[6]["text"])

	candle_off_area = current_location.get_node_or_null("candle_off_area")
	if candle_off_area:
		candle_off_area.visible = true
		candle_off_area.monitoring = true
		candle_off_area.body_entered.connect(_on_candle_off_area_entered)

	if player_danilo:
		tip_shocked = player_danilo.get_node_or_null("tip_shocked")
		if tip_shocked:
			tip_shocked.visible = false

	npc_ghost = current_location.get_node_or_null("y-sorted/npc_shadowy_ghost")
	if npc_ghost:
		npc_ghost.visible = false
		npc_ghost.z_index = 9999

func _on_candle_off_area_entered(body):
	if body != player_danilo or candle_off_area_triggered:
		return
	candle_off_area_triggered = true

	player_danilo.set_physics_process(false)
	if candle_off_area:
		candle_off_area.monitoring = false

	var sprite: AnimatedSprite2D = player_danilo.get_node_or_null("AnimatedSprite2D") if player_danilo else null
	if sprite:
		sprite.animation = "idle_up"
		sprite.frame = 0

	if tip_shocked:
		tip_shocked.visible = true
		
	DialogueManager.show_dialogue_balloon(A_4S_3, "while_shadow_ghost_forward")
	await DialogueManager.dialogue_ended
	_flicker_all_candles_creepy()
	_start_ghost_slow_approach()

func _flicker_all_candles_creepy() -> void:
	var all_lights := []

	var big_light: PointLight2D = current_location.get_node_or_null("map/candle/big_candle/PointLight2D")
	if big_light:
		all_lights.append(big_light)

	for i in range(1, 7):
		var light: PointLight2D = current_location.get_node_or_null("map/candle/candle_%d/PointLight2D" % i)
		if light:
			all_lights.append(light)

	var flicker_count := 15
	var interval := 3.0 / flicker_count
	_start_creepy_flicker(all_lights, flicker_count, interval)


func _start_creepy_flicker(lights: Array, count: int, interval: float) -> void:
	if count <= 0:
		for light in lights:
			light.visible = false
			light.texture_scale = 1.0
		bgm_chapel.stop()
		sfx_creepy.play()
		bgm_appear.play()
		DialogueManager.show_dialogue_balloon(A_4S_3, "after_shadow_ghost_forward")
		if tip_shocked:
			tip_shocked.visible = false
		if player_danilo:
			player_danilo.set_physics_process(true)
		if npc_ghost:
			npc_ghost.visible = false
		if ghost_move_timer:
			ghost_move_timer.stop()
		return

	for light in lights:
		light.visible = randi() % 2 == 0
		var scale_val := 4.5 + randf() * 1.5
		var tween := create_tween()
		tween.tween_property(light, "texture_scale", scale_val, interval / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var t := Timer.new()
	t.wait_time = interval
	t.one_shot = true
	t.autostart = true
	t.timeout.connect(func():
		_start_creepy_flicker(lights, count - 1, interval)
		t.queue_free()
	)
	add_child(t)

func _start_ghost_slow_approach() -> void:
	sfx_appear.play()
	if not npc_ghost or not player_danilo:
		return

	npc_ghost.visible = true

	var offset = (npc_ghost.global_position - player_danilo.global_position).normalized() * 200
	var target_pos = player_danilo.global_position - offset

	var tween = create_tween()
	tween.tween_property(npc_ghost, "global_position", target_pos, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	add_child(ghost_move_timer)
	_enable_chapel_exit_area()

func _enable_chapel_exit_area() -> void:
	if not current_location:
		return
	exit_area = current_location.get_node_or_null("exit_area")
	if exit_area:
		exit_area.visible = true
		exit_area.monitoring = true
		exit_area.body_entered.connect(_on_exit_area_entered)
	can_exit_chapel = true

func _on_exit_area_entered(body: Node) -> void:
	sfx_creepy.stop()
	bgm_appear.stop()
	if body != player_danilo or not can_exit_chapel:
		return

	can_exit_chapel = false
	exit_area.monitoring = false
	if tip_shocked:
		tip_shocked.visible = false

	player_danilo.set_physics_process(false)
	CHAPEL_EXTERIOR.set_meta("from_chapel", true)

	TransitionFade.transition()
	await SignalBus.on_transition_finished
	_switch_to_chapel_exterior(true) 

func _on_exit_chapel_exterior_entered(body: Node) -> void:
	if body != player_danilo or exit_chapel_exterior_triggered:
		return
	exit_chapel_exterior_triggered = true

	if exit_chapel_exterior_area:
		exit_chapel_exterior_area.monitoring = false

	scene_3_done()
	
func _trigger_dizzy_effect():
	var meds_taken := SaveManager.get_count_meds_taken()  # or your function
	if meds_taken > 1:
		return  # Skip if player took 2+ meds

	if not dizzy_overlay:
		return

	dizzy_overlay.visible = true
	var t := Timer.new()
	t.wait_time = dizzy_duration
	t.one_shot = true
	t.autostart = true
	t.timeout.connect(func():
		dizzy_overlay.visible = false
		t.queue_free()
	)
	add_child(t)
	
func _start_dizzy_timer():
	if dizzy_timer:
		dizzy_timer.queue_free()

	dizzy_timer = Timer.new()
	dizzy_timer.wait_time = 30.0 
	dizzy_timer.one_shot = false
	dizzy_timer.autostart = true
	dizzy_timer.timeout.connect(_trigger_dizzy_effect)
	add_child(dizzy_timer)
# ===================
# COMPLETE SCENE
# ===================
func scene_3_done() -> void:
	ObjectiveManager.complete_objective(8)
	Hud.hide_objectives()
	Hud.clear_objectives()
	SaveManager.game_save.current_act = "act_4"
	SaveManager.game_save.current_scene = "scene_3"
	GameState.save_game()
	print("ACT 4 SCENE 3 DONE")
	SignalBus.act_num_scene_num_done.emit(
		"act_4", 
		"scene_3", 
        "res://scenes/game/act_4/scene_4/dark_forest.tscn"
	)
		
 