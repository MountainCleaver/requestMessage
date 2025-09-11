extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	color_rect.visible = false;
	animation_player.animation_finished.connect(_on_animation_finished);


func transition():
	color_rect.visible = true;
	animation_player.play("fade_to_black");


func _on_animation_finished(animationName):
	if animationName == "fade_to_black":
		SignalBus.on_transition_finished.emit()
		animation_player.play("fade_to_normal");
	elif animationName == "fade_to_normal":
		color_rect.visible = false;
