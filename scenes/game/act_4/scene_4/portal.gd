extends Area2D

const TARGET_SCENE := "res://scenes/game/act_4/scene_4/cliff.tscn"

func _ready() -> void:
	body_entered.connect(_on_to_cliff_body_entered)

func _on_to_cliff_body_entered(body: Node2D) -> void:
	if body.name != "player_danilo":
		return

	# Transition effect
	TransitionFade.transition()
	await SignalBus.on_transition_finished

	get_tree().change_scene_to_file(TARGET_SCENE)
