extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	color_rect.visible = false;
	animation_player.animation_finished.connect(_on_animation_finished);


func transition():
	color_rect.visible = true;
	animation_player.play("fade_to_white");


func _on_animation_finished(animationName):
	if animationName == "fade_to_white":
		SignalBus.on_white_transition_finished.emit()
		animation_player.play("fade_to_normal_white");
	elif animationName == "fade_to_normal_white":
		color_rect.visible = false;
