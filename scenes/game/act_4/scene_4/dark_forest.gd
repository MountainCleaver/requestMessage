extends Node2D

@onready var player_danilo: CharacterBody2D = $"y-sorted/player_danilo"

func _ready() -> void:
	if get_tree().has_meta("last_portal_name"):
		var last_portal_name = str(get_tree().get_meta("last_portal_name"))
		var target_portal = get_node_or_null(NodePath(last_portal_name))
		if target_portal:
			player_danilo.global_position = target_portal.global_position
			print("Player returned from:", last_portal_name)
