extends Control

func _process(delta: float) -> void:
	if Input.is_action_pressed("accept"):
		SignalBus.next_scene.emit("res://scenes/menu/menu_create_acc_bday_gender.tscn");
