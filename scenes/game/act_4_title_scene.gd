extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Fade-in title scene
	animation_player.play("in_animation")
	await animation_player.animation_finished
	
	# All 3 lines stacked vertically
	var lines = [
		"“If I turn back now...“",
		"“I might never find the truth.“"
	]
	
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	
	# Fade transition after click
	SignalBus.next_scene.emit("res://scenes/game/act_4/scene_1/act_4_scene_1.tscn")
		
 