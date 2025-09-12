extends Control

@onready var text_edit: LineEdit = $holder/line_edit_username
@onready var toggle_visibility: TextureButton = $holder/line_edit_password/toggle_visibility
@onready var line_edit_password: LineEdit = $holder/line_edit_password

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	line_edit_password.secret = true;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass;


func _on_toggle_visibility_toggled(toggled_on: bool) -> void:
	print("is visible: " + str(toggled_on) );
	if toggled_on:
		line_edit_password.secret = false;
	elif !toggled_on:
		line_edit_password.secret = true;
