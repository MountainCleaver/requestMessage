extends Control

@onready var button: Button = $proceed/Button

var logged_in: bool = false

func _ready() -> void:

	var user_data: Dictionary = Session.get_user_info()
	logged_in = not user_data.is_empty()
	button.pressed.connect(_on_proceed_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("accept"):
		_go_next_scene()

func _on_proceed_pressed() -> void:
	_go_next_scene()

func _go_next_scene() -> void:
	if not logged_in:
		SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn")
	else:
		SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
