extends Control

@onready var exit: Button = $screen/EXIT
@onready var appointment_1 = $appointment_1
@onready var appointment_2 = $appointment_2
@onready var appointment_3 = $appointment_3

func _ready() -> void:
	# Connect appointment signal
	SignalBus.connect("appointment_selected", Callable(self, "_on_appointment_selected"))

	# Default all appointments hidden first
	appointment_1.visible = false
	appointment_2.visible = false
	appointment_3.visible = false

	# Wait a frame to ensure everything is ready
	await get_tree().process_frame

	# Show last selected or default to appointment_3
	if SignalBus.last_appointment_selected != "":
		_on_appointment_selected(SignalBus.last_appointment_selected)
	else:
		_on_appointment_selected("appointment_3")  # default visible

	# Setup exit button
	if exit:
		exit.pressed.connect(Callable(self, "_on_exit_pressed"))
		exit.mouse_filter = Control.MOUSE_FILTER_STOP

	# Make appointments ignore mouse so exit is always clickable
	for child in get_children():
		if child.name.begins_with("appointment"):
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_appointment_selected(name: String) -> void:
	for child in get_children():
		if child.name.begins_with("appointment"):
			child.visible = child.name == name
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_exit_pressed() -> void:
	queue_free()
