extends Node2D

@onready var storm_animation: AnimationPlayer = $storm_animation
@onready var camera_animation: AnimationPlayer = $camera_animation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera_animation.play("intro_pan");


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	storm_animation.play("storm");
