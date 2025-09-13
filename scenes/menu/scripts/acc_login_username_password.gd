extends Control

@onready var signup_link: Button = $holder/signup_link

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_signup_link_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_create_acc_creds.tscn");
