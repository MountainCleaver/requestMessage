extends Control
@onready var button: Button = $proceed/Button

func _ready() -> void:
	#TODO -> CHECK IF PLAYER LOGGED IN OR NOT. IF YES, THEN THE FUNCTION B ELOW SHOULD TAKE PLAYER TO MAIN MENU AND NOT TO LOGIN/SIGNUP PAGE
	pass;

func _process(delta: float) -> void:
	if Input.is_action_pressed("accept") or button.button_pressed:
		SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn");
