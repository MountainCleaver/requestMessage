extends Control

@onready var danilo_btn: Button = $screen/Panel/MarginContainer5/Panel/DANILO
@onready var mira_btn: Button = $screen/MarginContainer6/Panel2/MIRA
@onready var exit: Button = $screen/Panel/EXIT

var previous_scene: Control = null
var active_call: Control = null
var danilo_called: bool = false  # Track if Danilo has been called

func _ready() -> void:
	danilo_btn.pressed.connect(_on_danilo_pressed)
	mira_btn.pressed.connect(_on_mira_pressed)
	exit.pressed.connect(_on_exit_pressed)

	if not SignalBus.is_connected("call_completed", Callable(self, "_on_call_completed")):
		SignalBus.connect("call_completed", Callable(self, "_on_call_completed"))
	
	# Initialize Mira button state
	_update_mira_button_state()

func _on_danilo_pressed() -> void:
	_start_call("danilo")

func _on_mira_pressed() -> void:
	# Check if Danilo has been called first
	if not danilo_called:
		_show_cannot_call_message("You need to call Danilo first")
		return
	
	_start_call("mira")

func _start_call(target: String) -> void:
	print("Calling " + target.capitalize() + "...")

	danilo_btn.disabled = true
	mira_btn.disabled = true

	active_call = preload("res://scenes/game/wendy_call.tscn").instantiate()
	active_call.set_call_target(target)
	active_call.previous_scene = self
	get_parent().add_child(active_call)
	self.visible = false

func _on_exit_pressed() -> void:
	queue_free()
	if previous_scene:
		previous_scene.visible = true

func _on_call_completed(call_name: String) -> void:
	# Update call tracking
	if call_name == "danilo":
		danilo_called = true
		_update_mira_button_state()  # Update Mira button after Danilo call
	
	# Re-enable buttons
	danilo_btn.disabled = false
	mira_btn.disabled = false
	active_call = null
	if previous_scene:
		previous_scene.visible = true

# === NEW FUNCTIONS ===
func _update_mira_button_state() -> void:
	# Update Mira button based on whether Danilo has been called
	if danilo_called:
		# Mira can be called - enable button
		mira_btn.disabled = false
		mira_btn.modulate = Color.WHITE
		# Remove any tooltip if exists
		if mira_btn.has_method("set_tooltip_text"):
			mira_btn.set_tooltip_text("")
	else:
		# Mira cannot be called yet - disable and gray out
		mira_btn.disabled = true
		mira_btn.modulate = Color.GRAY
		# Add tooltip to explain why
		if mira_btn.has_method("set_tooltip_text"):
			mira_btn.set_tooltip_text("Call Danilo first")

func _show_cannot_call_message(message: String) -> void:
	# Show feedback that player needs to call Danilo first
	print(message)  # You can replace this with better UI feedback
	
	# Example: flash the Danilo button to draw attention
	_highlight_danilo_button()

func _highlight_danilo_button() -> void:
	# Simple visual feedback - you can enhance this with animations
	var original_color = danilo_btn.modulate
	danilo_btn.modulate = Color.YELLOW
	
	# Create a timer to reset the color
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	danilo_btn.modulate = original_color
