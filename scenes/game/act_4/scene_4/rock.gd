extends CharacterBody2D

@export var push_distance: float = 6.0
@export var push_duration: float = 0.3
@export var max_pushes: int = 2
@onready var sfx_push: AudioStreamPlayer = $SFX_PUSH

var push_count: int = 0
var is_pushed: bool = false
var target_position: Vector2

func _ready():
	if has_node("paper"):
		$paper.visible = false
		if $paper.has_method("set_monitoring"):
			$paper.set_monitoring(false)

func push_left():
	sfx_push.play()
	if is_pushed or push_count >= max_pushes:
		return
	is_pushed = true
	push_count += 1
	target_position = global_position + Vector2.LEFT * push_distance
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_position, push_duration)
	tween.finished.connect(_on_tween_finished)

func _on_tween_finished():
	is_pushed = false
	if has_node("paper"):
		$paper.visible = true
		if $paper.has_method("set_monitoring"):
			$paper.set_monitoring(true)
