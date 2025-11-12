extends Control

func _on_ok_pressed() -> void:
	queue_free()
	SignalBus.next_scene.emit("res://scenes/menu/boot_warning.tscn")
	Session.logout_session()

func _on_cancel_pressed() -> void:
	$Window.hide() 
	hide()

func _on_window_close_requested() -> void:
	$Window.hide()  
	hide()
