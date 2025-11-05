extends Control

@onready var line_edit_email: LineEdit = $holder/line_edit_email
@onready var btn_send: Button = $holder/btn_send
@onready var email_error: Label = $holder/email_error
@onready var http: HTTPRequest = find_child("HTTP_request")
@onready var menu_loading_screen: CanvasLayer = $"../menu_loading_screen"
@onready var button: Button = $"../back_tips/Panel/Button"

@onready var exit_confirmation_dialog: ConfirmationDialog = $"../ConfirmationDialog"
var exit_is_showing : bool = false

func _ready() -> void:
	http.request_completed.connect(_on_http_request_request_completed)
	btn_send.pressed.connect(_on_btn_send_pressed)
	button.pressed.connect(_on_back_pressed)
	menu_loading_screen.hide()

func _input(event: InputEvent) -> void:
	if event.is_action("escape"):
		if not exit_is_showing:
			exit_confirmation_dialog.show()
			exit_is_showing = true
		else:
			exit_confirmation_dialog.hide()
			exit_is_showing = false

func _on_btn_send_pressed() -> void:
	var email = line_edit_email.text.strip_edges()
	email_error.text = ""
	if email.is_empty():
		email_error.text = "Please enter your email."
		return

	# UI freeze/loading
	menu_loading_screen.show()
	btn_send.disabled = true

	var url = "https://requestmessage-admin.onrender.com/api/reset_password.php"
	var body = {"email": email}
	var headers = ["Content-Type: application/json"]
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_http_request_request_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	print("Password Reset Response: ", response_text)

	if response_code != 200:
		email_error.text = "Server error: " + str(response_code)
		menu_loading_screen.hide()
		btn_send.disabled = false
		return

	var json = JSON.parse_string(response_text)
	if typeof(json) != TYPE_DICTIONARY:
		email_error.text = "Invalid server response"
		menu_loading_screen.hide()
		btn_send.disabled = false
		return

	if json.get("success") == true:
		var popup = preload("res://scenes/menu/acc_reset_pass_succesfully.tscn").instantiate()
		add_child(popup)
		
		var ok_btn = popup.get_node("holder/btn_ok") 
		ok_btn.pressed.connect(func():
			line_edit_email.text = ""      
			popup.queue_free()             
		)
	else:
		email_error.text = str(json.get("message", "Unknown error"))

	menu_loading_screen.hide()
	btn_send.disabled = false

func _on_back_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn")
	queue_free()

func _on_confirmation_dialog_confirmed() -> void:
	get_tree().quit()

func _on_confirmation_dialog_canceled() -> void:
	pass

func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
