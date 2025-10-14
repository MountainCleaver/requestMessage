extends Node2D

var first_time_in: bool = true

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


func _on_house_door_outside_body_entered(body: Node2D) -> void:
	if first_time_in:
		first_time_in = false
		return
	if body.name == "player_danilo":
		SignalBus.in_npc.emit("door_outside")


func _on_house_door_outside_body_exited(body: Node2D) -> void:
	if body.name == "player_danilo":
		SignalBus.out_npc.emit("door_outside")
