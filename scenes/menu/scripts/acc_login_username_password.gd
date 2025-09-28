extends Control

@onready var line_edit_username: LineEdit = $holder/line_edit_username
@onready var line_edit_password: LineEdit = $holder/line_edit_password
@onready var login_error: Label = $holder/login_error
@onready var btn_login: Button = $holder/btn_login
@onready var login_link: Button = $holder/login_link
@onready var http: HTTPRequest = find_child("HTTP_request")

func _ready() -> void:
	line_edit_password.secret = true
	http.request_completed.connect(_on_HTTP_request_request_completed)
	btn_login.pressed.connect(_on_btn_login_pressed)

func _on_btn_login_pressed() -> void:
	var username = line_edit_username.text
	var password = line_edit_password.text

	if username.is_empty() or password.is_empty():
		login_error.text = "Fields cannot be empty."
		return

	var url = "https://requestmessage-admin.onrender.com/api/login.php"
	var body = {"username": username, "password": password}
	var headers = ["Content-Type: application/json"]

	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_HTTP_request_request_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	print("Login Response: ", response_text)

	if response_code != 200:
		login_error.text = "Server error: " + str(response_code)
		return

	var json = JSON.parse_string(response_text)
	if typeof(json) != TYPE_DICTIONARY:
		login_error.text = "Invalid server response"
		return

	if json.get("status") == "success":
		# Optional: store user_id or other info for later
		get_tree().set_meta("user_id", json.get("user_id"))
		SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
	else:
		login_error.text = str(json.get("message", "Unknown error"))

func _on_signup_link_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_create_acc_bday_gender.tscn")
