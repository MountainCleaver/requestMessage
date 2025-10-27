extends Node2D

@onready var good_light = $good_lighting
@onready var bad_light = $bad_lighting

var flicker_timer := 0.0
var flicker_speed := 2.0
var flicker_min := 0.99
var flicker_max := 1.0

func _ready():
	update_lighting_based_on_meds()

func _process(delta):
	var meds_done_count := SaveManager.get_count_meds_taken()
	if meds_done_count < 2:
		bad_light.visible = true
		good_light.visible = false
		
		flicker_timer += delta * flicker_speed
		bad_light.energy = lerp(flicker_min, flicker_max, (sin(flicker_timer) + 1.0) / 2.0)
	else:
		bad_light.visible = false
		good_light.visible = true
		bad_light.energy = flicker_max


func update_lighting_based_on_meds():
	var meds_done_count := SaveManager.get_count_meds_taken()
	print("[MedsLighting] Meds taken count:", meds_done_count)
	
	if meds_done_count >= 2:
		good_light.visible = true
		bad_light.visible = false
		print("[MedsLighting] Lighting: GOOD")
	else:
		good_light.visible = false
		bad_light.visible = true
		print("[MedsLighting] Lighting: BAD")
