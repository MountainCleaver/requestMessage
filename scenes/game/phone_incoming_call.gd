extends Control

@onready var timer_label: Label = $timer_label
@onready var button: Button = $HBoxContainer/Button
@onready var reject_button: Button = $HBoxContainer2/Button
@onready var h_box_container: HBoxContainer = $HBoxContainer
@onready var label: Label = $Label
@onready var image_profile: TextureRect = $image_margin/image_background/image_profile

var time_passed: float = 0.0
var running: bool = false

var portrait_path_template: String = "res://assets/character_sprites/portrait_%s.png"
var portrait_path: String

func _ready() -> void:
	timer_label.hide()
	SignalBus.call_done.connect(_on_call_done)
	
	# Example (you can call this from outside later)
	set_caller("Unknown Sender")

func _process(delta: float) -> void:
	if running:
		time_passed += delta
		_update_time()

func _on_button_pressed() -> void:
	timer_label.show()
	if not running:
		start_time()
		running = true
	h_box_container.visible = false

	button.visible = false
	reject_button.visible = false
	
	SignalBus.player_answered_call.emit()

func _on_reject_button_pressed() -> void:
	SignalBus.player_rejected_call.emit()
	await get_tree().process_frame

	
func _on_call_done() -> void:
	stop_time()
	queue_free()

# ==========================
# CALL TIMER FUNCTIONS
# ==========================
func start_time() -> void:
	running = true

func stop_time() -> void:
	running = false

func _update_time() -> void:
	var minutes := int(time_passed) / 60
	var seconds := int(time_passed) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

# ==========================
# CALLER HANDLER
# ==========================
func set_caller(name: String) -> void:
	label.text = "Incoming call from %s" % name
	
	var formatted_name := name.to_lower().replace(" ", "_")
	portrait_path = portrait_path_template % formatted_name
	
	if ResourceLoader.exists(portrait_path):
		var tex = load(portrait_path)
		image_profile.texture = tex
		print("Loaded portrait for:", name)
	else:
		push_warning("Portrait not found for: %s" % name)
		image_profile.texture = null
