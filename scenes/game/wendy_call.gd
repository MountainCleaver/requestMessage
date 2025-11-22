extends Control

@onready var end_btn: Button = $call_screen/Panel2/ENDCALL

@onready var status_label: Label = $call_screen/Panel2/status
@onready var name_label: Label = $call_screen/Panel2/danilo
@onready var icon: TextureRect = $call_screen/Panel2/Icon2 

@onready var panel_logo: Panel = $call_screen/Panel2/LOGOPANEL
@onready var panel_icon: TextureRect = $call_screen/Panel2/Icon2
@onready var timer_label: Label = $call_screen/Panel2/timer_label

var A_2S_4: Resource

var call_target: String = ""
var previous_scene: Control = null
var return_to_app_call := false
var dialogue_started := false  

var call_time: float = 0.0
var timer_running: bool = false

# =========================
# === CALL SETUP LOGIC ====
# =========================

func _load_dialogue() -> void:
	var lang = Settings.settings.dialogue_language
	var path: String
	if lang == "en":
		path = "res://dialogues/act_2/scene_4/a2s4_en.dialogue"
	else:
		path = "res://dialogues/act_2/scene_4/a2s4.dialogue"
	
	A_2S_4 = load(path)
	
func set_call_target(target: String) -> void:
	await ready 

	call_target = target

	match call_target:
		"danilo":
			name_label.text = "Danilo"
			status_label.text = "Cannot be reached..."
			if icon:
				icon.texture = preload("res://assets/character_sprites/portrait_danilo.png")
			# For Danilo, end the call after 2 seconds
			await get_tree().create_timer(2.0).timeout
			_end_call()
			
		"mira":
			name_label.text = "Tita Mira"
			status_label.text = "Calling..."
			if icon:
				icon.texture = preload("res://assets/character_sprites/portrait_mira.png")
			
			# Start dialogue for Mira
			if not dialogue_started:
				dialogue_started = true
				var dialogue_callable = Callable(self, "_on_mira_dialogue_done")
				if not SignalBus.is_connected("dialogue_finished", dialogue_callable):
					SignalBus.connect("dialogue_finished", dialogue_callable)
				call_deferred("_start_mira_dialogue") 

# =========================
# === READY / MAIN FLOW ===
# =========================
func _ready() -> void:	
	_load_dialogue() 
	if end_btn:
		end_btn.pressed.connect(_on_end_pressed)
	
	timer_label.hide()
	await get_tree().process_frame


func _start_timer() -> void:
	timer_label.show() 
	status_label.visible = false
	timer_running = true 
	call_time = 0.0

	
func _process(delta: float) -> void:
	if timer_running:
		call_time += delta
		_update_timer_label()
		
func _update_timer_label() -> void:
	var minutes := int(call_time) / 60
	var seconds := int(call_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
# =========================
# === MIRA DIALOGUE FLOW ==
# =========================
func _start_mira_dialogue() -> void:
	if status_label.text == "Call ended.":
		return

	DialogueManager.show_dialogue_balloon(
		A_2S_4,
		"call_mira"
	)
	await DialogueManager.dialogue_ended
	_start_timer()
	
	DialogueManager.show_dialogue_balloon(
		A_2S_4,
		"call_mira_convo"
	)
	await DialogueManager.dialogue_ended 


func _on_mira_dialogue_done() -> void:
	if call_target == "mira":
		var dialogue_callable = Callable(self, "_on_mira_dialogue_done")
		if SignalBus.is_connected("dialogue_finished", dialogue_callable):
			SignalBus.disconnect("dialogue_finished", dialogue_callable)
		_end_call()

# =========================
# === END CALL LOGIC ======
# =========================
func _on_end_pressed() -> void:
	if call_target == "mira":
		var dialogue_callable = Callable(self, "_on_mira_dialogue_done")
		if SignalBus.is_connected("dialogue_finished", dialogue_callable):
			SignalBus.disconnect("dialogue_finished", dialogue_callable)
		if DialogueManager.has_method("hide_dialogue_balloon"):
			DialogueManager.hide_dialogue_balloon()
		
		ObjectiveManager.complete_objective(3)
		print("End call objective completed")
	
	_end_call()

func _end_call() -> void:
	timer_running = false
	if status_label:
		status_label.text = "Call ended."
	print("Call with " + call_target + " ended.")
	
	timer_label.hide()
	SignalBus.emit_signal("call_completed", call_target)
	await get_tree().create_timer(1.0).timeout

	if call_target == "danilo":
		
		DialogueManager.show_dialogue_balloon(
			A_2S_4,
			"call_voicemail"
		)
		
		return_to_app_call = true

	if previous_scene:
		previous_scene.visible = true

	queue_free()
