extends Control
@onready var button: Button = $proceed/Button

func _ready() -> void:
	#TODO -> CHECK IF PLAYER LOGGED IN OR NOT. IF YES, THEN THE FUNCTION B ELOW SHOULD TAKE PLAYER TO MAIN MENU AND NOT TO LOGIN/SIGNUP PAGE
	pass;

func _process(delta: float) -> void:
	if Input.is_action_pressed("accept") or button.button_pressed:
		SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn");

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
