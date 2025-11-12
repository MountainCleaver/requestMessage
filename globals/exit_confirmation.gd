extends Control

func _on_yes_pressed() -> void:
	get_tree().quit()
	hide()

func _on_cancel_pressed() -> void:
	$Window.hide() 
	hide()

func _on_window_close_requested() -> void:
	$Window.hide()  
	hide()
