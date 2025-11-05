extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var act_title: Label = $act_title

func _ready() -> void:
	var total_karma = SaveManager.get_total_karma()

	if total_karma < 0:
		act_title.text = "The Unending Guilt"
	else:
		act_title.text = "Finally at Rest"

	act_title.visible = true
	act_title.modulate.a = 0.0

	animation_player.play("in_animation")
	await animation_player.animation_finished

	var lines = [ 
		"“He said he’d be back soon.“", 
		"“But that was yesterday.“", 
		"“Or... was it?“",
		"[shake rate=10 level=15]“Where could he be?“[/shake]"
		]
	
	await NarrationPanel.show_narration_typewriter(lines, 0.05)
	await NarrationPanel.hide_narration()

	SignalBus.next_scene.emit("res://scenes/game/act_6/scene_1/act_6_scene_1.tscn")
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
