extends Control

@onready var btn_accept: Button1 = $btn_accept
@onready var back: Button1 = $back_tips/back

func _ready():
	# Safe signal connection for mobile
	if btn_accept and btn_accept is Button1:
		btn_accept.pressed.connect(_on_accept_pressed)
	else:
		print("btn_accept missing or not of type Button1!")
	if back and back is Button1:
		back.pressed.connect(_on_back_pressed)
	else:
		print("back missing or not of type Button1!")

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
