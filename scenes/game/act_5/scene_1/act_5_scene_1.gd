extends Node2D 

# ===================
# PRELOADS
# ===================
const A_5S_1 = preload("res://dialogues/act_5/scene_1/a5s1.dialogue")
const DARK_FOREST = preload("res://scenes/game/act_5/scene_1/dark_forest.tscn")
const CHAPEL_EXTERIOR = preload("res://scenes/game/act_5/scene_1/chapel_exterior.tscn")
const CHAPEL_INTERIOR = preload("res://scenes/game/act_5/scene_1/chapel_interior.tscn")
const NARRATION_PANEL = preload("res://helpers/narration_panel.tscn")

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

# ===================
# OBJECTIVES
# ===================
var scene_objectives = [
	{"ID": 1, "text": "Return to the old chapel"},
	{"ID": 2, "text": "Light up all the candles"}
]

# ===================
# FLAGS
# ===================
var door_interacted = false
var can_use_door = false
var dialogue_triggered = false

var can_interact_candle := false
var candle_ignited := false
var lit_candles := {} # key: candle index (1-7), value: true
var total_candles := 7

# ===================
# READY
# ===================
func _ready():
	_game_state_flow()
	switch_location(DARK_FOREST)
	_start_scene()
	SignalBus.unknown_sender_unlocked = true
	SignalBus.unknown_sender_label_visible = false

func _game_state_flow() -> void:
	GameState.load_game()
	GameState.current_act = "act_5"
	GameState.current_scene = "scene_1"
	GameState.overwrite_current_scene_keep_previous()
	GameState.save_game()

# ===================
# START SCENE
# ===================
func _start_scene() -> void:
	await get_tree().process_frame
	Hud.show_objectives()
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	DialogueManager.show_dialogue_balloon(A_5S_1, "start")

func _on_dark_forest_entrance_entered(body: Node) -> void:
	if body != player_danilo:
		return 
	TransitionFade.transition()
	await SignalBus.on_transition_finished
	_switch_to_chapel_exterior()

# ===================
# SWITCH LOCATIONS
# ===================
func _switch_to_chapel_exterior() -> void:
	await get_tree().process_frame
	switch_location(CHAPEL_EXTERIOR)

func _switch_to_chapel_interior() -> void:
	switch_location(CHAPEL_INTERIOR)
	DialogueManager.show_dialogue_balloon(A_5S_1, "light_candle")
	await DialogueManager.dialogue_ended

	# Add objective for all candles (progress type)
	ObjectiveManager.add_progress_objective(scene_objectives[1]["ID"], scene_objectives[1]["text"], total_candles)
	_setup_all_candle_areas()

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
	
	if scene == DARK_FOREST:
		dark_forest_entrance_area = current_location.get_node_or_null("entrance")
	if dark_forest_entrance_area:
		dark_forest_entrance_area.body_entered.connect(_on_dark_forest_entrance_entered)
	if before_door_area:
		before_door_area.body_entered.connect(_on_before_door_area_body_entered)
	if door_area:
		door_area.body_entered.connect(_on_door_area_body_entered)
		door_area.body_exited.connect(_on_door_area_body_exited)

# ===================
# AREA HANDLERS
# ===================
func _on_before_door_area_body_entered(body):
	if body == player_danilo and not dialogue_triggered:
		dialogue_triggered = true
		player_danilo.set_physics_process(false)
		DialogueManager.show_dialogue_balloon(A_5S_1, "back_to_chapel_again")
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

# ===================
# INPUT HANDLER
# ===================
func _process(_delta):
	# Door interaction
	if can_use_door and not door_interacted and Input.is_action_just_pressed("interact"):
		_door_interacted()

	# Candle interaction
	if can_interact_candle and Input.is_action_just_pressed("interact"):
		var candle_index = current_location.get_meta("current_candle")
		if candle_index != null and not lit_candles.has(candle_index):
			_light_candle(candle_index)

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
	ObjectiveManager.complete_objective(1)
	_switch_to_chapel_interior()

# ===================
# CANDLE LOGIC
# ===================



func _setup_all_candle_areas() -> void:
	# Big candle
	var big_area = current_location.get_node_or_null("map/candle/big_candle/big_candle_area")
	if big_area:
		big_area.visible = true
		big_area.monitoring = true
		big_area.body_entered.connect(_on_candle_area_entered.bind(0)) # index 0 = big candle
		big_area.body_exited.connect(_on_candle_area_exited.bind(0))

	# Small candles 1-6
	for i in range(1, 7):
		var area = current_location.get_node_or_null("map/candle/candle_%d/candle_%d_area" % [i, i])
		if area:
			area.visible = true
			area.monitoring = true
			area.body_entered.connect(_on_candle_area_entered.bind(i))
			area.body_exited.connect(_on_candle_area_exited.bind(i))
		var sprite = current_location.get_node_or_null("map/candle/candle_%d/candle" % i)
		if sprite:
			sprite.region_rect = Rect2(0, 0, 9.6, 20)
		var light = current_location.get_node_or_null("map/candle/candle_%d/PointLight2D" % i)
		if light:
			light.visible = false

	# Big candle sprite/light
	if big_area:
		var big_sprite = current_location.get_node_or_null("map/candle/big_candle/candle")
		if big_sprite:
			big_sprite.region_rect = Rect2(0,0,20,29)
		var big_light = current_location.get_node_or_null("map/candle/big_candle/PointLight2D")
		if big_light:
			big_light.visible = false

func _on_candle_area_entered(body, index: int) -> void:
	if body != player_danilo:
		return
	
	# Only show tip if candle not yet lit
	if lit_candles.has(index):
		can_interact_candle = false
		if tip_interact:
			tip_interact.visible = false
		return
	
	can_interact_candle = true
	current_location.set_meta("current_candle", index)
	if tip_interact:
		tip_interact.visible = true
		
func _on_candle_area_exited(body, index: int) -> void:
	if body != player_danilo:
		return
	can_interact_candle = false
	current_location.set_meta("current_candle", null)
	if tip_interact:
		tip_interact.visible = false


func _light_candle(index: int) -> void:
	lit_candles[index] = true

	# Visuals
	var sprite_path = "map/candle/big_candle/candle" if index == 0 else "map/candle/candle_%d/candle" % index
	var light_path = "map/candle/big_candle/PointLight2D" if index == 0 else "map/candle/candle_%d/PointLight2D" % index

	var sprite: Sprite2D = current_location.get_node_or_null(sprite_path)
	var light: PointLight2D = current_location.get_node_or_null(light_path)

	if sprite:
		sprite.region_enabled = true
		sprite.region_rect = Rect2(21, 0, 20.8, 29) if index == 0 else Rect2(9,0,9,20)
	if light:
		light.visible = true
		light.texture_scale = 0.5
		var tween = create_tween()
		tween.tween_property(light, "texture_scale", 1.7 if index==0 else 5.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Hide tip interact immediately
	if tip_interact:
		tip_interact.visible = false

	# Update objective progre`ss
	ObjectiveManager.update_progress(scene_objectives[1]["ID"])

	# Check completion
	if lit_candles.size() >= total_candles:
		ObjectiveManager.complete_objective(scene_objectives[1]["ID"])
		DialogueManager.show_dialogue_balloon(A_5S_1, "all_candles_lit_up")
