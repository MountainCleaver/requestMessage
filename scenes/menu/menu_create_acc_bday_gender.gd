extends Control

@onready var exit_confirmation: Control = $ExitConfirmation
@onready var window: Window = $ExitConfirmation/Window
var exit_is_showing : bool = false

func _input(event: InputEvent) -> void:
	if event.is_action("escape"):
		if not exit_is_showing:
			exit_confirmation.show()
			window.show()
			exit_is_showing = true
		else:
			exit_confirmation.hide()
			window.hide()
			exit_is_showing = false
