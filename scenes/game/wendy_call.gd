extends Control

@onready var end_btn: Button = $call_screen/Panel2/ENDCALL
@onready var status_label: Label = $call_screen/Panel2/status
@onready var name_label: Label = $call_screen/Panel2/danilo

var call_target: String = ""
var previous_scene: Control = null
var return_to_app_call := false
var dialogue_started := false  # Prevents dialogue from starting multiple times

func set_call_target(target: String) -> void:
	call_target = target
	if name_label:
		name_label.text = target.capitalize()
	if status_label:
		status_label.text = "Calling..."
	print("📞 Calling " + target + "...")

func _ready() -> void:
	if end_btn:
		end_btn.pressed.connect(_on_end_pressed)

	if call_target == "danilo":
		await get_tree().create_timer(3.0).timeout
		_end_call()
	elif call_target == "mira" and not dialogue_started:
		dialogue_started = true

		var dialogue_callable = Callable(self, "_on_mira_dialogue_done")
		if not SignalBus.is_connected("dialogue_finished", dialogue_callable):
			SignalBus.connect("dialogue_finished", dialogue_callable)

		# Delay showing dialogue by 0.1 sec to ensure the scene is fully ready
		call_deferred("_start_mira_dialogue")

func _start_mira_dialogue() -> void:
	if status_label.text == "Call ended.":
		# Call already ended, don’t start dialogue
		return
	DialogueManager.show_dialogue_balloon(
		preload("res://dialogues/act_2/scene_4/a2s4.dialogue"),
		"call_mira_convo"
	)

func _on_end_pressed() -> void:
	if call_target == "mira":
		var dialogue_callable = Callable(self, "_on_mira_dialogue_done")
		if SignalBus.is_connected("dialogue_finished", dialogue_callable):
			SignalBus.disconnect("dialogue_finished", dialogue_callable)
		if DialogueManager.has_method("hide_dialogue_balloon"):
			DialogueManager.hide_dialogue_balloon()  # immediately stops dialogue
	_end_call()

func _on_mira_dialogue_done() -> void:
	# Automatically end the call when dialogue finishes
	if call_target == "mira":
		var dialogue_callable = Callable(self, "_on_mira_dialogue_done")
		if SignalBus.is_connected("dialogue_finished", dialogue_callable):
			SignalBus.disconnect("dialogue_finished", dialogue_callable)
		_end_call()

func _end_call() -> void:
	if status_label:
		status_label.text = "Call ended."
	print("📞 Call with " + call_target + " ended.")

	# Emit call_completed safely
	SignalBus.emit_signal("call_completed", call_target)

	await get_tree().create_timer(1.0).timeout

	# Show voicemail dialogue for Danilo
	if call_target == "danilo":
		DialogueManager.show_dialogue_balloon(
			preload("res://dialogues/act_2/scene_4/a2s4.dialogue"),
			"call_voicemail"
		)
		return_to_app_call = true

	# Return to previous scene if exists
	if previous_scene:
		previous_scene.visible = true

	queue_free()
