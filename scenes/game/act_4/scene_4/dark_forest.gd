extends Node2D

@onready var player_danilo: CharacterBody2D = $"y-sorted/player_danilo"

var scene_objectives = [
	{"ID": 1, "text": "Go to the north side of the dark forest"},
]

func _ready() -> void:
	FlashlightManager.set_current_scene("act_4", "scene_4")
	FlashlightManager.enable_flashlight_by_cash()
	player_danilo.last_direction = Vector2.UP
	Hud.show_objectives()
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	if get_tree().has_meta("last_portal_name"):
		var last_portal_name = str(get_tree().get_meta("last_portal_name"))
		var target_portal = get_node_or_null(NodePath(last_portal_name))
		if target_portal:
			player_danilo.global_position = target_portal.global_position
			print("Player returned from:", last_portal_name)
