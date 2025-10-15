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
var lighter_area: Area2D
var lighter_node: Node2D
var big_candle_area: Area2D
var exit_area: Area2D
var exit_chapel_exterior_area: Area2D
var signage: Area2D


# ===================
# OBJECTIVES
# ===================
var scene_objectives = [
	{"ID": 1, "text": "Return to the old chapel"},
	{"ID": 2, "text": "Find the hidden path"}
]

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

	
func _switch_to_chapel_exterior() -> void:
	await get_tree().process_frame
	switch_location(CHAPEL_EXTERIOR)
		
func _switch_to_chapel_interior() -> void:
	Hud.clear_objectives()
	Hud.hide_objectives()
	switch_location(CHAPEL_INTERIOR)
	
	await get_tree().process_frame
	#DialogueManager.show_dialogue_balloon(A_4S_3, "exploration_chat")
	await DialogueManager.dialogue_ended
	Hud.phone_outro()
	await get_tree().create_timer(1).timeout
	Hud.show_objectives()
	#ObjectiveManager.add_progress_objective(explore_objective_id, "Explore the place", explore_goal)


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
