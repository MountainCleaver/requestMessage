extends Control

@onready var chat: Button = $screen/MarginContainer/GridContainer/CHAT
@onready var flashlight: Button = $screen/MarginContainer/GridContainer/FLASHLIGHT
@onready var sched: Button = $screen/MarginContainer/GridContainer/SCHED
@onready var gallery: Button = $screen/MarginContainer/GridContainer/GALLERY

signal lock_pressed_for_last_objective
signal phone_locked

func _ready() -> void:
	_update_flashlight_button()

func _update_flashlight_button() -> void:
	var act = FlashlightManager.data.get("current_act", "")
	var scene = FlashlightManager.data.get("current_scene", "")
	var scene_number = 0
	if scene != "":
		scene_number = int(scene.replace("scene_", ""))

	# If Lola Ising cash was given, disable forever
	if SaveManager.has_given_lola_ising_cash():
		flashlight.disabled = true
		return

	# Always enable phone flashlight starting from Act 4 Scene 1
	if act == "act_4" and scene_number >= 1:
		flashlight.disabled = false
		return

	# Enable only if Act 3 Scene 4 or later (for earlier acts)
	if act == "act_3" and scene_number >= 4:
		flashlight.disabled = false
	else:
		flashlight.disabled = true


func set_current_scene_and_update(act: String, scene: String) -> void:
	FlashlightManager.set_current_scene(act, scene)
	_update_flashlight_button()

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
	if flashlight.disabled:
		print("Phone flashlight button is locked.")
		return

	FlashlightManager.toggle_phone_flashlight()
	if FlashlightManager.phone_flashlight_enabled:
		print("Phone flashlight ON")
	else:
		print("Phone flashlight OFF")
		
	Hud.phone_outro()
	queue_free()

		
func _on_sched_pressed() -> void:
	var parent = get_parent()
	var schedule_app = preload("res://scenes/game/app_schedule.tscn").instantiate()
	parent.add_child(schedule_app)
	SignalBus.sched_opened.emit()

func _on_gallery_pressed() -> void:
	pass
