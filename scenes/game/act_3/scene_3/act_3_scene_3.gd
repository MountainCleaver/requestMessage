extends Node2D

@onready var locations: Node2D = $locations

# LOCATIONS
const DANILO_HOUSE = preload ("res://scenes/game/act_3/scene_3/danilo_hometown_house.tscn")
const HOMETOWN_TOWN = preload ("res://scenes/game/act_3/scene_3/danilo_hometown.tscn")
const TOWN_CENTER = preload ("res://scenes/game/act_3/scene_3/hometown_town_center.tscn")
const DRUG_STORE = preload ("res://scenes/game/act_3/scene_3/drugstore.tscn")

var current_location: Node = null

func _ready() -> void:
	# Load the starting location
	switch_location(DANILO_HOUSE)

func switch_location(scene: PackedScene) -> void:
	# Remove current location if it exists
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()

	# Add the new location
	current_location = scene.instantiate()
	locations.add_child(current_location)

func to_rizal_park() -> void:
	ObjectiveManager.complete_objective(1)
	TransitionFade.transition();
	await SignalBus.on_transition_finished;
	switch_location(HOMETOWN_TOWN);

func wendy_follow() -> void:
	current_location.wendy_follow();

func wendy_unfollow() -> void:
	current_location.wendy_unfollow();

func set_table_used(table_name : String) -> void:
	current_location.set_table_used(table_name);

func scene_2_done() -> void:
	Hud.hide_objectives();



const a3s3 = preload("res://dialogues/act_3/scene_3/a3s3.dialogue")
