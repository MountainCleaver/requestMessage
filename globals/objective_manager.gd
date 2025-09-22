extends Node

var objectives: Dictionary = {}

func add_objective(id: int, text: String) -> void:
	Hud.new_objective(id, text)
	objectives[id] = text

func complete_objective(id: int) -> void:
	if id in objectives:
		Hud.done_objective(id, objectives[id])
		objectives.erase(id)
