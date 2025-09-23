extends Control

@onready var chat: Button = $screen/MarginContainer/GridContainer/CHAT
@onready var flashlight: Button = $screen/MarginContainer/GridContainer/FLASHLIGHT
@onready var sched: Button = $screen/MarginContainer/GridContainer/SCHED
@onready var gallery: Button = $screen/MarginContainer/GridContainer/GALLERY

func _on_lock_pressed() -> void:
	queue_free();



func _on_chat_pressed() -> void:
	var parent = get_parent();	
	var chat_app = preload("res://scenes/game/app_chat.tscn").instantiate();
	parent.add_child(chat_app)


func _on_flashlight_pressed() -> void:
	pass # Replace with function body.


func _on_sched_pressed() -> void:
	pass # Replace with function body.


func _on_gallery_pressed() -> void:
	pass # Replace with function body.
