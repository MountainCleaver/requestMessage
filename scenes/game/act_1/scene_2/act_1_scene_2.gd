extends Node2D

# NODES
@onready var locations: Node2D = $locations

# LOCATIONS
const DANILO_NEIGHBORHOOD = preload("res://scenes/game/act_1/scene_2/danilo_neighborhood.tscn")
const RIZAL_PARK = preload("res://scenes/game/act_1/scene_2/rizal_park.tscn")

var current_location: Node = null
var met_wendy : bool = false;

func _ready() -> void:
	FlashlightManager.set_current_scene("act_1", "scene_2")
	FlashlightManager.disable_flashlights()
	# Load the starting location
	switch_location(DANILO_NEIGHBORHOOD)

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
	switch_location(RIZAL_PARK);

func wendy_follow() -> void:
	current_location.wendy_follow();

func wendy_unfollow() -> void:
	current_location.wendy_unfollow();

func set_table_used(table_name : String) -> void:
	current_location.set_table_used(table_name);

func scene_2_done() -> void:
	Hud.hide_objectives();
	
	SaveManager.game_save.current_act = "act_1"
	SaveManager.game_save.current_scene = "scene_2" # badly named I admit. this is for the 'continue' part in main menu
	SaveManager.save_game()
	SignalBus.act_num_scene_num_done.emit("act_1", "scene_2", "res://scenes/game/act_1/scene_3/act_1_scene_3.tscn") # caught in save manager
	Hud.clear_objectives();
	print("act 1 scene 1 is done")

func get_scene_type() -> String:
	return "game"
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
