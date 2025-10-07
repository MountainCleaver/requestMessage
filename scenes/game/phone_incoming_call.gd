extends Control

@onready var timer_label: Label = $timer_label
@onready var button: Button = $HBoxContainer/Button
@onready var h_box_container: HBoxContainer = $HBoxContainer

var time_passed : float = 0.0;
var running : bool = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer_label.hide()
	SignalBus.call_done.connect(_on_call_done)


func _process(delta: float) -> void:
	if running:
		time_passed += delta
		_update_time()

func _on_button_pressed() -> void:
	timer_label.show()
	if not running:
		start_time()
		running = true;
	h_box_container.visible = false;
	SignalBus.player_answered_call.emit()

# call
func _on_call_done () -> void:
	stop_time()
	queue_free()

# call timer functions
func start_time() -> void:
	running = true;

func stop_time() -> void:
	running = false;

func _update_time() -> void:
	var minutes := int(time_passed) / 60;
	var seconds := int(time_passed) % 60;
	timer_label.text = "%02d:%02d" % [minutes, seconds]
