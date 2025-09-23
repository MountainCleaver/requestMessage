extends Control

@onready var exit: Button = $screen/MarginContainer/HBoxContainer/EXIT



func _on_exit_pressed() -> void:
	queue_free();
