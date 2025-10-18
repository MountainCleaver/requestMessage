extends Node2D

@onready var door_area: Area2D = $drugstore/areas/door_area
@onready var npc_area: Area2D = $drugstore/areas/npc_area

var first_time_in : bool = true

func _on_door_area_body_entered(body: Node2D) -> void:
	if first_time_in:
		first_time_in = false
		return
	SignalBus.in_npc.emit("drugstore_door_inside")

func _on_door_area_body_exited(body: Node2D) -> void:
	SignalBus.out_npc.emit("drugstore_door_inside")

func _on_npc_area_body_entered(body: Node2D) -> void:
	SignalBus.in_npc.emit("pharmacist")

func _on_npc_area_body_exited(body: Node2D) -> void:
	SignalBus.out_npc.emit("pharmacist")
