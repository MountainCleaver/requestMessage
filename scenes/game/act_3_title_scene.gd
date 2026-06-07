extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Fade-in title scene
	animation_player.play("in_animation")
	await animation_player.animation_finished
	
	# All 3 lines stacked vertically
	var lines = [
		"“Memory is a cruel storyteller.”",
		"“It lets me see only pieces I’m meant to see.”",
		"“And now, I’m back... to where everything started.”"
	]
	
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	
	# Fade transition after click
	SignalBus.next_scene.emit("res://scenes/game/act_3/scene_1/act_3_scene_1.tscn")
		
 