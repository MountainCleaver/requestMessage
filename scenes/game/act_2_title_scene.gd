extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Fade-in title scene
	animation_player.play("in_animation")
	await animation_player.animation_finished
	
	# All 3 lines stacked vertically
	var lines = [
		"“It came out of nowhere.”",
		"“A message I wasn’t expecting.”",
		"“And now I can’t stop thinking about it.”"
	]
	
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()
	
	# Fade transition after click
	SaveManager.game_save.current_act = "act_1"
	SaveManager.game_save.current_scene = "scene_4"
	SignalBus.act_num_scene_num_done.emit("act_1", "scene_4", "res://scenes/game/act_2/scene_1/act_2_scene_1.tscn")
