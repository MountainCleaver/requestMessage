extends Node2D

const RIZAL_PARK_AFTER_HABULAN = preload("res://scenes/game/act_1/scene_3/rizal_park_after_habulan.tscn")
const HABULAN_AREA = preload("res://scenes/game/act_1/scene_3/habulan_area.tscn")

@onready var locations: Node2D = $locations

var current_location : Node = null;

func _ready() -> void:
	FlashlightManager.set_current_scene("act_1", "scene_3")
	FlashlightManager.disable_flashlights()
	BgmManager.stop_music()
	_switch_location_to(HABULAN_AREA);
	SignalBus.habulan_done.connect(_switch_to_rizal);

func _switch_to_rizal():
	WhiteTransitionFade.transition()
	await SignalBus.on_white_transition_finished
	_switch_location_to(RIZAL_PARK_AFTER_HABULAN);
	pass;

func _switch_location_to(scene: PackedScene):
	if current_location and current_location.is_inside_tree():
		current_location.queue_free()

	# Add the new location
	current_location = scene.instantiate()
	locations.add_child(current_location)

func re_enable_collisions() -> void:
	current_location.re_enable_collisions()

func leave_the_park() -> void:
	current_location._leave_the_park()

func wendy_walk_away() -> void :
	current_location.wendy_walk_away();

func scene_3_done() -> void:
	current_location.scene_3_done();

func get_scene_type() -> String:
	return "game"
