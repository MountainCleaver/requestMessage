extends Control

@onready var line_edit_email: LineEdit = $holder/line_edit_email
@onready var btn_login: Button = $holder/btn_login
@onready var email_error: Label = $holder/email_error
@onready var confirmation_dialog: ConfirmationDialog = $"../ConfirmationDialog"

func _ready() -> void:
	print("email_error: ", email_error)
	btn_login.pressed.connect(_on_btn_login_pressed)

func _on_btn_login_pressed() -> void:
	var email = line_edit_email.text.strip_edges()
	email_error.text = ""
	if email.is_empty():
		email_error.text = "Please enter your email."
		return

	confirmation_dialog.text = "We already sent the message, please check your email."
	confirmation_dialog.popup_centered()
