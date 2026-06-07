extends Node2D

func _on_drugstore_door_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("drugstore_door_outside")

func _on_drugstore_door_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("drugstore_door_outside")

func _on_tricycle_area_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("tricycle_town_center")

func _on_tricycle_area_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("tricycle_town_center")
		
 