extends Control

@onready var line_edit_user: LineEdit = $holder/line_edit_username_email
@onready var line_edit_password: LineEdit = $holder/line_edit_password
@onready var login_error: Label = $holder/login_error
@onready var btn_login: Button = $holder/btn_login
@onready var login_link: Button = $holder/login_link
@onready var signup_link: Button = $holder/signup_link
@onready var forgot_pass: Button = $holder/forgot_pass
@onready var http: HTTPRequest = find_child("HTTP_request")
@onready var menu_loading_screen: CanvasLayer = $"../menu_loading_screen"
@onready var exit_confirmation_dialog: ConfirmationDialog = $"../ConfirmationDialog"
@onready var toggle_password_visibility: TextureButton1 = $holder/line_edit_password/toggle_visibility
var exit_is_showing : bool = false


func _ready() -> void:
	print(signup_link)  # Will print "[Button:xxxx]" if found, "null" if not
	signup_link.pressed.connect(_on_signup_link_pressed)
	line_edit_password.secret = true
	http.request_completed.connect(_on_HTTP_request_request_completed)
	btn_login.pressed.connect(_on_btn_login_pressed)
	menu_loading_screen.hide()
	forgot_pass.pressed.connect(_on_forgot_pass_pressed)
	toggle_password_visibility.connect("toggled", Callable(self, "_on_toggle_visibility_toggled"))


func _input(event: InputEvent) -> void:
	if event.is_action("escape"):
		if not exit_is_showing:
			exit_confirmation_dialog.show()
			exit_is_showing = true
		else:
			exit_confirmation_dialog.hide()
			exit_is_showing = false

func _on_btn_login_pressed() -> void:
	var user_input = line_edit_user.text.strip_edges()
	var password = line_edit_password.text

	if user_input.is_empty() or password.is_empty():
		login_error.text = "All fields are required."
		return

	var username = ""
	var email = ""

	# Detect if input is an email or username
	if user_input.find("@") != -1:
		email = user_input
	else:
		username = user_input

	menu_loading_screen.show()
	btn_login.disabled = true
	login_link.disabled = true

	var url = "https://requestmessage-admin.onrender.com/api/login.php"
	var body = {"username": username, "email": email, "password": password}
	var headers = ["Content-Type: application/json"]
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_HTTP_request_request_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	print("Login Response: ", response_text)

	if response_code != 200:
		login_error.text = "Server error: " + str(response_code)
		menu_loading_screen.hide()
		btn_login.disabled = false
		login_link.disabled = false
		return

	var json = JSON.parse_string(response_text)
	if typeof(json) != TYPE_DICTIONARY:
		login_error.text = "Invalid server response"
		menu_loading_screen.hide()
		btn_login.disabled = false
		login_link.disabled = false
		return

	if json.get("status") == "success":
		var user_ID = json.user_id
		var actual_username = json.username if json.has("username") else line_edit_user.text
		Global.username = actual_username
		Session.save_session(actual_username, user_ID)
		SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
	else:
		login_error.text = str(json.get("message", "Unknown error"))

	menu_loading_screen.hide()
	btn_login.disabled = false
	login_link.disabled = false

func _on_toggle_visibility_toggled(toggled_on: bool) -> void:
	line_edit_password.secret = not toggled_on

func _on_signup_link_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/privacy_policy.tscn")

func _on_forgot_pass_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_reset_password.tscn")

func _on_confirmation_dialog_confirmed() -> void:
	get_tree().quit()

func _on_confirmation_dialog_canceled() -> void:
	pass

func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
