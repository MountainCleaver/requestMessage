extends Control

@onready var btn_accept: Button = $btn_accept
@onready var back_button: Button = $back_tips/Panel/Button

func _ready():
	btn_accept.pressed.connect(_on_accept_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_accept_pressed():
	SignalBus.next_scene.emit("res://scenes/menu/menu_create_acc_bday_gender.tscn")
	queue_free()

func _on_back_pressed():
	SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn")
	queue_free()

func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
