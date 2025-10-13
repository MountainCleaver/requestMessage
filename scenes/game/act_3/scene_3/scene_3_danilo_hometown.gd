extends Node2D

func _on_tricycle_area_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("tricycle_hometown")


func _on_tricycle_area_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("tricycle_hometown")


func _on_karatula_area_body_entered(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("karatula")


func _on_karatula_area_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("karatula")
