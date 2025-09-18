extends Control

@onready var signup_link: Button = $holder/login_link
@onready var btn_login: Button = $holder/btn_login

var api : String = "http://192.168.100.57/chat-app/apis/auth/login.php"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	btn_login.pressed.connect(_goto_main_menu);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_signup_link_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_create_acc_bday_gender.tscn");

func _goto_main_menu(): #temporary fn
	SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
	
