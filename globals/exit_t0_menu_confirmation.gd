extends Control

func _on_yes_pressed() -> void:
	$Window.hide()
	hide()
	
	var pause_screen = get_parent()
	if pause_screen:
		pause_screen.dialog_showing = false

	await get_tree().create_timer(0.05).timeout

	if pause_screen:
		pause_screen._on_exit_main_menu_dialog_confirmed()

func _on_cancel_pressed() -> void:
	$Window.hide()
	hide()

func _on_window_close_requested() -> void:
	$Window.hide()
	hide()
