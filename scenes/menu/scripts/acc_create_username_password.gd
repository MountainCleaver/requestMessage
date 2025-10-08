extends Control

@onready var line_edit_username: LineEdit = $holder/line_edit_username
@onready var line_edit_password: LineEdit = $holder/line_edit_password
@onready var line_edit_password_confirm: LineEdit = $holder/line_edit_password_confirm
@onready var err_password: Label = $holder/line_edit_password_confirm/err_password
@onready var btn_create: Button = $holder/btn_create
@onready var some_nice_words: Label = $holder/some_nice_words
@onready var http: HTTPRequest = find_child("HTTP_request")
@onready var login_link: Button = $holder/login_link
@onready var menu_loading_screen: CanvasLayer = $"../menu_loading_screen"

@onready var toggle_visibility: TextureButton = $holder/line_edit_password/toggle_visibility
@onready var toggle_visibility_confirm: TextureButton = $holder/line_edit_password_confirm/toggle_visibility_confirm

func _ready() -> void:
	menu_loading_screen.hide()
	line_edit_password.secret = true
	line_edit_password_confirm.secret = true

	http.request_completed.connect(_on_HTTP_request_request_completed)

func _input(event: InputEvent) -> void:
	if event.is_action("escape"):
		SignalBus.next_scene.emit("res://scenes/menu/menu_create_acc_bday_gender.tscn")

func _on_btn_create_pressed() -> void:

	var username = line_edit_username.text
	var password = line_edit_password.text
	var password_confirm = line_edit_password_confirm.text

	if username.is_empty() or password.is_empty() or password_confirm.is_empty():
		some_nice_words.text = "Fields cannot be empty"
	elif password.length() < 6:
		err_password.text = "Password must be at least 6 characters long!"
	elif password_confirm != password:
		err_password.text = "Passwords do not match!"
	else:
		menu_loading_screen.show()
		login_link.disabled = true;
		btn_create.disabled = true;
		var url = "https://requestmessage-admin.onrender.com/api/register.php"

		# Retrieve metadata set from previous scene
		var birthday = get_tree().get_meta("birthday")
		var gender = get_tree().get_meta("gender")

		var body = {
			"username": username,
			"password": password,
			"birthday": birthday,
			"gender": gender
		}
		var headers = ["Content-Type: application/json"]

		http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


func _on_HTTP_request_request_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	print("Register Response: ", response_text)

	if response_code != 200:
		some_nice_words.text = "Server error: " + str(response_code)
		return

	var json = JSON.parse_string(response_text)
	if typeof(json) != TYPE_DICTIONARY:
		some_nice_words.text = "Invalid server response"
		return

	if json.get("status") == "success":
		var popup = preload("res://scenes/menu/acc_create_successfully.tscn").instantiate()
		add_child(popup)
		
		var user_ID = json.user_id
		
		var ok_btn = popup.get_node("holder/btn_ok")
		ok_btn.pressed.connect(func():
			Session.save_session(line_edit_username.text, user_ID)
			popup.queue_free()
			SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
		)
	else:
		some_nice_words.text = str(json.get("message", "Unknown error"))
	
	menu_loading_screen.hide()
	login_link.disabled = false;
	btn_create.disabled = false;


func _on_login_link_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn")


func _on_toggle_visibility_toggled(toggled_on: bool) -> void:
	line_edit_password.secret = not toggled_on

func _on_toggle_visibility_confirm_toggled(toggled_on: bool) -> void:
	line_edit_password_confirm.secret = not toggled_on
