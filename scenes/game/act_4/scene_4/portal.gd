extends Area2D

const TARGET_SCENE := "res://scenes/game/act_4/scene_4/cliff.tscn"

func _ready() -> void:
	body_entered.connect(_on_to_cliff_body_entered)

func _on_to_cliff_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return

	if get_tree().has_meta("forest_to_cliff_used") and get_tree().get_meta("forest_to_cliff_used"):
		print("Forest → Cliff portal is now deactivated. Cannot use again.")
		return

	print("Teleporting from Forest → Cliff...")

	get_tree().set_meta("forest_to_cliff_used", true)

	get_tree().set_meta("last_portal_name", name)
	get_tree().set_meta("last_portal_position", global_position)

	# Transition effect
	TransitionFade.transition()
	await SignalBus.on_transition_finished

	get_tree().change_scene_to_file(TARGET_SCENE)
