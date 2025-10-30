extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var button: Button = $back_tips/Panel/Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.play("scrolling");
	animation_player.animation_finished.connect(_exit_credits);
	button.pressed.connect(_exit_credits);

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_exit_credits();


func _exit_credits() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
	
