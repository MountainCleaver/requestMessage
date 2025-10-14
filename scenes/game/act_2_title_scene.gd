extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Fade-in title scene
	animation_player.play("in_animation")
	await animation_player.animation_finished
	
	# All 3 lines stacked vertically
	var lines = [
		"Some messages are not meant to be ignored.",
		"…Some memories are best left forgotten.",
		"…But they find you anyway."
	]
	
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	
	# Fade transition after click
	SignalBus.next_scene.emit("res://scenes/game/act_2/scene_1/act_2_scene_1.tscn")
