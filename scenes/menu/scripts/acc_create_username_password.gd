extends Control

@onready var line_edit_username: LineEdit = $holder/line_edit_username
@onready var line_edit_email: LineEdit = $holder/line_edit_email
@onready var verify: Button = $holder/line_edit_email/verify
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

var email_verified: bool = false
var last_verified_email: String = ""
var verification_popup: Control
var pending_email: String = ""
var verifying_code: bool = false
var current_sent_code_email: String = "" 

func _ready() -> void:
	menu_loading_screen.hide()
	line_edit_password.secret = true
	line_edit_password_confirm.secret = true
	http.request_completed.connect(_on_HTTP_request_request_completed)
	verify.pressed.connect(_on_btn_verify_pressed)
	btn_create.pressed.connect(_on_btn_create_pressed)
	login_link.pressed.connect(_on_login_link_pressed)
	toggle_visibility.toggled.connect(_on_toggle_visibility_toggled)
	toggle_visibility_confirm.toggled.connect(_on_toggle_visibility_confirm_toggled)
	line_edit_email.text_changed.connect(_on_email_text_changed)

func _input(event: InputEvent) -> void:
	if event.is_action("escape"):
		SignalBus.next_scene.emit("res://scenes/menu/menu_create_acc_bday_gender.tscn")

func _on_email_text_changed(new_text: String) -> void:
	if new_text != current_sent_code_email:
		email_verified = false
		current_sent_code_email = ""
		last_verified_email = ""
		some_nice_words.text = ""
		if verification_popup:
			verification_popup.queue_free()

func _on_btn_verify_pressed() -> void:
	var email = line_edit_email.text
	some_nice_words.text = ""
	if email.is_empty():
		some_nice_words.text = "Enter your email first!"
		return

	var email_regex = RegEx.new()
	email_regex.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
	if not email_regex.search(email):
		some_nice_words.text = "Invalid email format!"
		return

	# Reuse code if for same email
	if email == current_sent_code_email and email != "":
		pending_email = email
		open_verification_popup() 
		return

	# Send new code if email changed or first time
	pending_email = email
	var url = "https://requestmessage-admin.onrender.com/api/send_verification.php"
	var body = {"email": email}
	var headers = ["Content-Type: application/json"]
	verifying_code = false
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	menu_loading_screen.show()

func _on_btn_create_pressed() -> void:
	var username = line_edit_username.text
	var email = line_edit_email.text
	var password = line_edit_password.text
	var password_confirm = line_edit_password_confirm.text

	if username.is_empty() or email.is_empty() or password.is_empty() or password_confirm.is_empty():
		some_nice_words.text = "Fields cannot be empty"
		return

	var email_regex = RegEx.new()
	email_regex.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
	if not email_regex.search(email):
		some_nice_words.text = "Invalid email format"
		return

	if password.length() < 6:
		err_password.text = "Password must be at least 6 characters long!"
		return
	elif password_confirm != password:
		err_password.text = "Passwords do not match!"
		return

	if not email_verified or line_edit_email.text != last_verified_email:
		some_nice_words.text = "Verify your email first!"
		return

	menu_loading_screen.show()
	login_link.disabled = true
	btn_create.disabled = true

	var url = "https://requestmessage-admin.onrender.com/api/register.php"
	var birthday = get_tree().get_meta("birthday")
	var gender = get_tree().get_meta("gender")

	var body = {
		"username": username,
		"email": email,
		"password": password,
		"birthday": birthday,
		"gender": gender
	}
	var headers = ["Content-Type: application/json"]
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_HTTP_request_request_completed(result, response_code, headers, body):
	menu_loading_screen.hide()
	var response_text = body.get_string_from_utf8()
	var json = JSON.parse_string(response_text)

	# Handle verification code check
	if verifying_code:
		if typeof(json) == TYPE_DICTIONARY:
			if json.has("status") and json["status"] == "success":
				email_verified = true
				last_verified_email = pending_email
				some_nice_words.text = "Email verified!"
				if verification_popup:
					verification_popup.queue_free()
			else:
				var msg = json["message"] if json.has("message") else "Code incorrect!"
				if verification_popup:
					verification_popup.get_node("holder/code/err_username").text = msg
		else:
			if verification_popup:
				verification_popup.get_node("holder/code/err_username").text = "Verification failed! Invalid response."
		return

	# Handle send code to email
	if not verifying_code:
		if response_code == 200 and typeof(json) == TYPE_DICTIONARY:
			if json.has("status") and json["status"] == "success":
				current_sent_code_email = pending_email
				open_verification_popup()
				return
			else:
				var msg = json["message"] if json.has("message") else "Failed to send code."
				some_nice_words.text = msg
				return
		elif pending_email != "" and not verifying_code:
			some_nice_words.text = "Could not send code! Invalid server response."
			return

	# Registration response
	if response_code != 200:
		some_nice_words.text = "Server error: " + str(response_code)
		login_link.disabled = false
		btn_create.disabled = false
		return

	if typeof(json) == TYPE_DICTIONARY and json.has("status"):
		if json["status"] == "success":
			var popup = preload("res://scenes/menu/acc_create_successfully.tscn").instantiate()
			add_child(popup)
			var user_ID = json["user_id"] if json.has("user_id") else ""
			var ok_btn = popup.get_node("holder/btn_ok")
			ok_btn.pressed.connect(func():
				Session.save_session(line_edit_username.text, user_ID)
				popup.queue_free()
				SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn")
			)
		else:
			var msg = json["message"] if json.has("message") else "Unknown error"
			some_nice_words.text = msg
	else:
		some_nice_words.text = "Invalid server response"

	login_link.disabled = false
	btn_create.disabled = false

func open_verification_popup():
	verification_popup = preload("res://scenes/menu/verify_email.tscn").instantiate()
	add_child(verification_popup)
	verification_popup.get_node("holder/title/subtitle").text = "Please check your email or SPAM for the code!"
	verification_popup.get_node("holder/btn_ok").pressed.connect(_on_verification_code_entered)
	verification_popup.get_node("holder/btn_close").pressed.connect(_on_verification_popup_closed)

func _on_verification_popup_closed():
	if verification_popup:
		verification_popup.queue_free()

func _on_verification_code_entered():
	var code = verification_popup.get_node("holder/code").text
	var url = "https://requestmessage-admin.onrender.com/api/verify_code.php"
	var body = {"email": pending_email, "code": code}
	var headers = ["Content-Type: application/json"]
	verifying_code = true
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	menu_loading_screen.show()

func _on_login_link_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn")

func _on_toggle_visibility_toggled(toggled_on: bool) -> void:
	line_edit_password.secret = not toggled_on

func _on_toggle_visibility_confirm_toggled(toggled_on: bool) -> void:
	line_edit_password_confirm.secret = not toggled_on

func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
