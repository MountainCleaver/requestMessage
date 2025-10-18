extends Node

var objectives: Dictionary = {}       

func add_objective(id: int, text: String, color: Color = Color.BLACK) -> void:
	Hud.new_objective(id, text, color)
	objectives[id] = {"text": text, "type": "normal"}

func add_progress_objective(id: int, base_text: String, goal: int, color: Color = Color.BLACK) -> void:
	var progress_text = "%s (0/%d)" % [base_text, goal]
	Hud.new_objective(id, progress_text, color)
	objectives[id] = {"text": base_text, "current": 0, "goal": goal, "type": "progress"}

func update_progress(id: int, amount: int = 1) -> void:
	if id in objectives and objectives[id]["type"] == "progress":
		objectives[id]["current"] += amount
		var current = objectives[id]["current"]
		var goal = objectives[id]["goal"]
		var base_text = objectives[id]["text"]
		
		# Update display
		var progress_text = "%s (%d/%d)" % [base_text, current, goal]
		Hud.update_objective_text(id, progress_text)
		
		# Auto-complete when done
		if current >= goal:
			complete_objective(id)

func complete_objective(id: int) -> void:
	if id in objectives:
		Hud.done_objective(id, objectives[id]["text"])
		objectives.erase(id)

func empty_objectives () -> void:
	if objectives:
		objectives.clear()
# -------------------------
# New: reset progress back to 0 (keeps objective active)
# -------------------------
func reset_progress(id: int) -> void:
	# Only valid for existing progress objectives
	if id in objectives and objectives[id].has("type") and objectives[id]["type"] == "progress":
		objectives[id]["current"] = 0
		var base_text = objectives[id]["text"]
		var goal = objectives[id]["goal"]
		var progress_text = "%s (0/%d)" % [base_text, goal]
		# Update HUD to show 0 progress
		Hud.update_objective_text(id, progress_text)
	else:
		# If the objective doesn't exist, do nothing (safe fail)
		return
