extends Node2D

@onready var good_light = $good_lighting
@onready var bad_light = $bad_lighting

func _ready():
	update_lighting_based_on_meds()

func update_lighting_based_on_meds():
	var meds_done_count := SaveManager.get_count_meds_taken()
	print("[MedsLighting] Meds taken count:", meds_done_count)
	
	# Lighting logic: 1 = BAD, 2-3 = GOOD
	if meds_done_count >= 2:
		good_light.visible = true
		bad_light.visible = false
		print("[MedsLighting] Lighting: GOOD")
	else:
		good_light.visible = false
		bad_light.visible = true
		print("[MedsLighting] Lighting: BAD")
