extends Node2D

@onready var good_light = $good_lighting
@onready var bad_light = $bad_lighting

func update_lighting_based_on_meds():
	var meds = SaveManager.get_count_meds_taken()
	
	if meds >= 2:
		good_light.visible = true
		bad_light.visible = false
	else:
		good_light.visible = false
		bad_light.visible = true
