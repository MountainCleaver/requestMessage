extends Control
@onready var panel: Panel = $Panel
@onready var label: Label = $Panel/Label
@onready var label_animation: AnimationPlayer = $label_animation

func _ready() -> void:
	# display frame first before going next line
	await get_tree().process_frame
	
	# save game
	SaveManager.save_game()
	await get_tree().process_frame
	# show for atleast one second
	await get_tree().create_timer(1).timeout
	SaveManager.save_game_next_scene();
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
