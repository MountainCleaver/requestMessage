extends Control

@onready var toggle_visibility: TextureButton = $holder/line_edit_password/toggle_visibility
@onready var toggle_visibility_confirm: TextureButton = $holder/line_edit_password_confirm/toggle_visibility_confirm

@onready var line_edit_username: LineEdit = $holder/line_edit_username
@onready var line_edit_password: LineEdit = $holder/line_edit_password
@onready var line_edit_password_confirm: LineEdit = $holder/line_edit_password_confirm

@onready var err_password: Label = $holder/line_edit_password_confirm/err_password

@onready var btn_create: Button = $holder/btn_create
@onready var some_nice_words: Label = $holder/some_nice_words

@onready var login_link: Button = $holder/login_link

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	line_edit_password.secret = true;
	line_edit_password_confirm.secret = true;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass;


func _on_toggle_visibility_toggled(toggled_on: bool) -> void:
	print("is visible: " + str(toggled_on) );
	if toggled_on:
		line_edit_password.secret = false;
	elif !toggled_on:
		line_edit_password.secret = true;

func _on_toggle_visibility_confirm_toggled(toggled_on: bool) -> void:
	print("confirm is visible" + str(toggled_on));
	if toggled_on:
		line_edit_password_confirm.secret = false;
	elif !toggled_on:
		line_edit_password_confirm.secret = true;


func _on_btn_create_pressed() -> void:
	
	var username = line_edit_username.text;
	var password = line_edit_password.text;
	var password_confirm = line_edit_password_confirm.text;
	
	if username.is_empty() or password.is_empty() or password_confirm.is_empty():
		some_nice_words.text = "Fields cannot be empty";
	elif password_confirm != password:
		err_password.text = "passwords do not match!"


func _on_login_link_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn");
