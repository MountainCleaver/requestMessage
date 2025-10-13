extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	SignalBus.in_npc.emit("door_inside")


func _on_area_2d_body_exited(body: Node2D) -> void:
	SignalBus.out_npc.emit("door_inside")
