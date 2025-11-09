extends Node2D

@onready var player_danilo: CharacterBody2D = $"y-sorted/player_danilo"
@onready var dizzy_overlay: ColorRect = $ColorRect
@onready var explorer_hud: CanvasLayer = $explorer_hud
var dizzy_timer: Timer

var scene_objectives = [
	{"ID": 1, "text": "Go to the north side of the dark forest"},
]

func _ready() -> void:
	FlashlightManager.set_current_scene("act_4", "scene_4")
	FlashlightManager.enable_flashlight_by_cash()
	_trigger_dizzy_state()
	player_danilo.last_direction = Vector2.UP
	explorer_hud.show_current_location(3)
	Hud.show_objectives()
	ObjectiveManager.add_objective(scene_objectives[0]["ID"], scene_objectives[0]["text"])
	if get_tree().has_meta("last_portal_name"):
		var last_portal_name = str(get_tree().get_meta("last_portal_name"))
		var target_portal = get_node_or_null(NodePath(last_portal_name))
		if target_portal:
			player_danilo.global_position = target_portal.global_position
			print("Player returned from:", last_portal_name)

func _start_dizzy_timer():
	if dizzy_timer:
		dizzy_timer.queue_free()
	
	dizzy_timer = Timer.new()
	dizzy_timer.wait_time = 30.0  # every 30 seconds
	dizzy_timer.one_shot = false
	dizzy_timer.autostart = true
	dizzy_timer.timeout.connect(_trigger_dizzy_state)
	add_child(dizzy_timer)
	
func _trigger_dizzy_state(duration: float = 1.0):
	var meds_count = SaveManager.get_count_meds_taken()
	if meds_count > 1:
		return
	
	dizzy_overlay.visible = true
	await get_tree().create_timer(duration).timeout
	dizzy_overlay.visible = false
	_start_dizzy_timer()
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
