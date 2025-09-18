extends Node2D

@onready var storm_animation: AnimationPlayer = $storm_animation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	storm_animation.play("storm");
