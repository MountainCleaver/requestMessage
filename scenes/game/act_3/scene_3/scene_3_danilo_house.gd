extends Node2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var bed_area: Area2D = $bed_area

func _ready() -> void:
	FlashlightManager.set_current_scene("act_3", "scene_3")
	FlashlightManager.disable_flashlights()
	SignalBus.sat_on_bed.connect(_on_sat_on_bed)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		if SignalBus.bought_meds:
			return
		SignalBus.in_npc.emit("door_inside")


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("")


func _on_bed_area_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		if SignalBus.bought_meds:
			SignalBus.in_npc.emit("bed")


func _on_bed_area_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		if SignalBus.bought_meds:
			SignalBus.out_npc.emit("bed")

func _on_sat_on_bed()->void:
	sprite_2d.visible = true
	bed_area.queue_free()
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
