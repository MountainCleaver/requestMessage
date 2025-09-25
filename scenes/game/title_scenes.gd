extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("in_animation");
	await animation_player.animation_finished;
	SignalBus.next_scene.emit("res://scenes/game/act_1/scene_1/act_1_scene_1.tscn"); 
