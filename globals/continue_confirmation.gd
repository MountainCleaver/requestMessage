extends Control

func _on_ok_pressed() -> void:
	if BgmManager:
		BgmManager.stop_music()
	SaveManager.load_game()
	var act: String = SaveManager.game_save.current_act
	var scene: String = SaveManager.game_save.current_scene
	SignalBus.next_scene.emit("res://scenes/game/" + act + "/" + scene + "/" + act + "_" + scene + ".tscn")

	$Window.hide()
	hide()
	
func _on_cancel_pressed() -> void:
	$Window.hide() 
	hide()

func _on_window_close_requested() -> void:
	$Window.hide()  
	hide()
