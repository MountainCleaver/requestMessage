extends Control

@onready var chat: Button = $screen/MarginContainer/GridContainer/CHAT
@onready var flashlight: Button = $screen/MarginContainer/GridContainer/FLASHLIGHT
@onready var sched: Button = $screen/MarginContainer/GridContainer/SCHED
@onready var gallery: Button = $screen/MarginContainer/GridContainer/GALLERY

signal lock_pressed_for_last_objective
signal phone_locked  # ADD THIS SIGNAL

func _on_lock_pressed() -> void:
	var current_scene = get_tree().current_scene

	if current_scene:
		# Optionally lock optional chats
		if "optional_chats_locked" in SignalBus:
			SignalBus.optional_chats_locked = true
			print("Optional chats locked for this scene.")

		# Check for chat completion and objective status
		if "all_chats_checked" in current_scene and current_scene.all_chats_checked() and not current_scene.set1_objective_done:
			emit_signal("lock_pressed_for_last_objective")
			return


	# Default lock behavior: just close phone
	# EMIT THE PHONE_LOCKED SIGNAL BEFORE CLOSING
	phone_locked.emit()


	queue_free()

func _on_chat_pressed() -> void:
	var parent = get_parent()
	var chat_app = preload("res://scenes/game/app_chat.tscn").instantiate()
	chat_app.previous_scene = self
	parent.add_child(chat_app)
	visible = false

	SignalBus.app_chat_opened.emit()
	
func _on_flashlight_pressed() -> void:
	pass

func _on_sched_pressed() -> void:
	var parent = get_parent()
	var schedule_app = preload("res://scenes/game/app_schedule.tscn").instantiate()
	parent.add_child(schedule_app)
	SignalBus.sched_opened.emit()

func _on_gallery_pressed() -> void:
	pass
