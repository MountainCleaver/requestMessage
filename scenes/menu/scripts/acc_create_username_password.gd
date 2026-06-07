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
#@onready var err_username: Label = $holder/err_username
@onready var err_username: Label = $holder/line_edit_username/err_username

var email_verified: bool = false
var last_verified_email: String = ""
var verification_popup: Control
var pending_email: String = ""
var current_request_type: String = ""  # "check_email", "verify_email", "verify_code", or "register"
var current_sent_code_email: String = ""  # Remember last code's email

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
	
	if OS.has_feature("web"):
		line_edit_password.secret_character = "·"
		line_edit_password_confirm.secret_character = "·"
		verify.remove_theme_font_override("font")

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
		print("[VERIFY] Reusing code for email: ", email)
		pending_email = email
		open_verification_popup()
		return

	# Check if email already exists first
	pending_email = email
	var url = "https://requestmessage-admin.onrender.com/api/check_email.php"
	var body = {"email": email}
	var headers = ["Content-Type: application/json"]
	current_request_type = "check_email"
	print("[VERIFY] Checking if email exists: ", email)
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
		print("[CREATE] Email not verified. email_verified: ", email_verified, " last_verified_email: ", last_verified_email)
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
	current_request_type = "register"
	print("[CREATE] Registering account with username: ", username, " email: ", email)
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_HTTP_request_request_completed(result, response_code, headers, body):
	menu_loading_screen.hide()
	var response_text = body.get_string_from_utf8()
	var json = JSON.parse_string(response_text)
	
	print("[HTTP_RESPONSE] Request Type: ", current_request_type)
	print("[HTTP_RESPONSE] Response Code: ", response_code)
	print("[HTTP_RESPONSE] Raw Response Text: ", response_text)
	print("[HTTP_RESPONSE] JSON Type: ", typeof(json))

	# Handle email existence check
	if current_request_type == "check_email":
		print("[CHECK_EMAIL] Processing email check response...")
		print("[CHECK_EMAIL] Raw response_text: ", response_text)
		print("[CHECK_EMAIL] Response length: ", response_text.length())
		
		if typeof(json) == TYPE_DICTIONARY:
			if json.has("status") and json["status"] == "success":
				print("[CHECK_EMAIL] Email available, sending code...")
				# Email is available, now send verification code
				var url = "https://requestmessage-admin.onrender.com/api/send_verification.php"
				var body_data = {"email": pending_email}
				var headers_verify = ["Content-Type: application/json"]
				current_request_type = "verify_email"
				http.request(url, headers_verify, HTTPClient.METHOD_POST, JSON.stringify(body_data))
			else:
				var msg = json["message"] if json.has("message") else "Email already exists!"
				print("[CHECK_EMAIL] FAILED! Message: ", msg)
				some_nice_words.text = msg
		else:
			some_nice_words.text = "Could not verify email!"
			print("[CHECK_EMAIL] ERROR! Invalid JSON response")
			print("[CHECK_EMAIL] JSON type: ", typeof(json))
		return

	# Handle verification code check
	if current_request_type == "verify_code":
		print("[VERIFY_CODE] Processing verification code response...")
		if typeof(json) == TYPE_DICTIONARY:
			if json.has("status") and json["status"] == "success":
				email_verified = true
				last_verified_email = pending_email
				some_nice_words.text = "Email verified!"
				print("[VERIFY_CODE] SUCCESS! Email verified: ", pending_email)
				if verification_popup:
					verification_popup.queue_free()
			else:
				var msg = json["message"] if json.has("message") else "Code incorrect!"
				print("[VERIFY_CODE] FAILED! Message: ", msg)
				if verification_popup:
					verification_popup.get_node("holder/code/err_username").text = msg
		else:
			print("[VERIFY_CODE] ERROR! Invalid JSON response")
			if verification_popup:
				verification_popup.get_node("holder/code/err_username").text = "Verification failed! Invalid response."
		return

	# Handle send code to email
	if current_request_type == "verify_email":
		print("[VERIFY_EMAIL] Processing send verification response...")
		if response_code == 200 and typeof(json) == TYPE_DICTIONARY:
			if json.has("status") and json["status"] == "success":
				current_sent_code_email = pending_email
				print("[VERIFY_EMAIL] SUCCESS! Code sent to: ", pending_email)
				open_verification_popup()
				return
			else:
				var msg = json["message"] if json.has("message") else "Failed to send code."
				print("[VERIFY_EMAIL] FAILED! Message: ", msg)
				some_nice_words.text = msg
				return
		else:
			print("[VERIFY_EMAIL] ERROR! Response code: ", response_code, " JSON type: ", typeof(json))
			some_nice_words.text = "Could not send code! Invalid server response."
			return

	# Handle registration
	if current_request_type == "register":
		print("[REGISTER] Processing registration response...")
		if response_code != 200:
			some_nice_words.text = "Server error: " + str(response_code)
			login_link.disabled = false
			btn_create.disabled = false
			print("[REGISTER] ERROR! Response code: ", response_code)
			return

		if typeof(json) != TYPE_DICTIONARY:
			some_nice_words.text = "Invalid server response: Not a dictionary"
			login_link.disabled = false
			btn_create.disabled = false
			print("[REGISTER] ERROR! JSON is not a dictionary. Type: ", typeof(json))
			return

		if not json.has("status"):
			some_nice_words.text = "Invalid server response: No status field"
			login_link.disabled = false
			btn_create.disabled = false
			print("[REGISTER] ERROR! No status field. Keys: ", json.keys())
			return

		if json["status"] == "success":
			print("[REGISTER] SUCCESS! Account created!")
			var popup = preload("res://scenes/menu/acc_create_successfully.tscn").instantiate()
			add_child(popup)
			var user_ID = json["user_id"] if json.has("user_id") else ""
			print("[REGISTER] User ID: ", user_ID)
			var ok_btn = popup.get_node("holder/btn_ok")
			ok_btn.pressed.connect(func():
				print("[REGISTER] Saving session for user: ", line_edit_username.text, " ID: ", user_ID)
				Session.save_session(line_edit_username.text, user_ID)
				popup.queue_free()
				SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn")
			)
		else:
			var msg = json["message"] if json.has("message") else "Unknown error"
			some_nice_words.text = str(msg)
			print("[REGISTER] FAILED! Message: ", msg)

		login_link.disabled = false
		btn_create.disabled = false

func open_verification_popup():
	verification_popup = preload("res://scenes/menu/verify_email.tscn").instantiate()
	add_child(verification_popup)
	verification_popup.get_node("holder/title/subtitle").text = "Please check your email or SPAM for the code!"
	verification_popup.get_node("holder/btn_ok").pressed.connect(_on_verification_code_entered)
	verification_popup.get_node("holder/btn_close").pressed.connect(_on_verification_popup_closed)

func _on_verification_popup_closed():
	print("[POPUP] Verification popup closed by user")
	if verification_popup:
		verification_popup.queue_free()

func _on_verification_code_entered():
	var code = verification_popup.get_node("holder/code").text
	var err_label = verification_popup.get_node("holder/code/err_username")
	
	if code.is_empty():
		err_label.text = "Please enter the code!"
		print("[VERIFY_CODE_SUBMIT] ERROR! Code is empty")
		return
	
	if code.length() < 8:
		err_label.text = "Code must be 8 characters!"
		print("[VERIFY_CODE_SUBMIT] ERROR! Code too short")
		return
	
	err_label.text = ""
	
	print("[VERIFY_CODE_SUBMIT] Code entered: ", code, " for email: ", pending_email)
	var url = "https://requestmessage-admin.onrender.com/api/verify_code.php"
	var body = {"email": pending_email, "code": code}
	var headers = ["Content-Type: application/json"]
	current_request_type = "verify_code"
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	menu_loading_screen.show()

func _on_login_link_pressed() -> void:
	print("[LOGIN_LINK] Navigating to login scene")
	SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn")

func _on_toggle_visibility_toggled(toggled_on: bool) -> void:
	line_edit_password.secret = not toggled_on

func _on_toggle_visibility_confirm_toggled(toggled_on: bool) -> void:
	line_edit_password_confirm.secret = not toggled_on

 