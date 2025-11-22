extends Control

@onready var exit: Button = %exit
@onready var uploader: Button1 = $Panel/UPLOADER
@onready var file_dialog: FileDialog = $Panel/UPLOADER/FileDialog
@onready var ss_preview: TextureRect = $Panel/ss_preview
@onready var bug_type: OptionButton = $Panel/HBoxContainer/BUG_TYPE/BUG_TYPE
@onready var text_edit: TextEdit = $Panel/TextEdit
@onready var submit: Button1 = $SUBMIT
@onready var clear: Button1 = $CLEAR
@onready var menu_loading_screen: CanvasLayer = $menu_loading_screen
#@onready var accept_dialog: AcceptDialog = $AcceptDialog
#@onready var empty_dialog: AcceptDialog = $EmptyDialog
#@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog
@onready var back: Button1 = $back_tips/back

@onready var empty_dialog1: Control = $empty_dialog
@onready var ok_button: Button1 = $empty_dialog/holder/btn_ok

@onready var accept_dialog1: Control = $accept_dialog
@onready var ok_button2: Button1 = $accept_dialog/holder/btn_ok1
@onready var label: Label = $accept_dialog/holder/subtitle

@onready var submit_confirmation: Control = $Submit_confirmation
@onready var window1: Window = $Submit_confirmation/Window
@onready var yes_button: Button1 = $Submit_confirmation/Window/Yes
@onready var cancel_button: Button1 = $Submit_confirmation/Window/Cancel
@onready var label2: Label = $Submit_confirmation/Window/Label

@onready var clear_confirmation: Control = $Clear_confirmation
@onready var window2: Window = $Clear_confirmation/Window
@onready var yes_button2: Button1 = $Clear_confirmation/Window/Yes
@onready var cancel_button2: Button1 = $Clear_confirmation/Window/Cancel
@onready var label3: Label = $Clear_confirmation/Window/Label

@onready var exit_confirmation: Control = $Exit_confirmation
@onready var window3: Window = $Exit_confirmation/Window
@onready var yes_button3: Button1 = $Exit_confirmation/Window/Yes
@onready var cancel_button3: Button1 = $Exit_confirmation/Window/Cancel
@onready var label4: Label = $Exit_confirmation/Window/Label

const BASIS_33 = preload("res://assets/fonts/basis33.ttf")
const MAX_SCREENSHOT_SIZE_MB = 6
const MAX_SCREENSHOT_SIZE = MAX_SCREENSHOT_SIZE_MB * 1024 * 1024
@onready var bug_type_popup = bug_type.get_popup()
var pending_action: String = ""
var file_picker = null 

func _ready() -> void:
	accept_dialog1.hide()
	menu_loading_screen.hide()
	empty_dialog1.hide()
	
	file_dialog.filters = ["*.png ; PNG Images", "*.jpg ; JPEG Images"]
	file_dialog.file_selected.connect(Callable(self, "_on_file_selected"))
	_style_popup(bug_type_popup)
	
	back.pressed.connect(_on_back_pressed)
	ok_button.pressed.connect(_on_btn_ok_pressed)
	ok_button2.pressed.connect(_on_btn_ok1_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	cancel_button2.pressed.connect(_on_cancel_pressed)
	cancel_button3.pressed.connect(_on_cancel_pressed)
	yes_button.pressed.connect(_submit_bug_report)
	yes_button2.pressed.connect(_clear_report_fields)
	yes_button3.pressed.connect(_on_yes_button3_pressed)
	
	print("Engine.get_singleton_list(): ", Engine.get_singleton_list())
	if Engine.has_singleton("GodotFilePicker"):
		file_picker = Engine.get_singleton("GodotFilePicker")
		print("GodotFilePicker singleton found and ready!")
		file_picker.file_picked.connect(_on_file_picked)
	else:
		print("ERROR: GodotFilePicker plugin not found or not loaded")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_show_confirm_dialog("exit")

func _on_exit_pressed() -> void:
	_show_confirm_dialog("exit")

func _on_uploader_pressed() -> void:
	if file_picker:
		file_picker.openFilePicker("image/*")
		print("GodotFilePicker: Invoked openFilePicker('image/*')")
	else:
		file_dialog.visible = true

func _on_file_selected(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	var size = 0
	if file:
		size = file.get_length()
	print("File selected: %s, Size: %d bytes" % [path, size])
	if size > MAX_SCREENSHOT_SIZE:
		label.text = "Selected image is too large (max %d MB).\nPlease select a smaller file." % MAX_SCREENSHOT_SIZE_MB
		#accept_dialog.popup_centered()
		return
	uploader.text = path
	var image = Image.new()
	var err = image.load(path)
	print("Image load error code: %d" % err)
	if err == OK:
		var tex = ImageTexture.create_from_image(image)
		ss_preview.texture = tex

func _on_file_picked(temp_path: String, mime_type: String) -> void:
	var file = FileAccess.open(temp_path, FileAccess.READ)
	var size = 0
	if file:
		size = file.get_length()
	print("Picked file: %s, Size: %d bytes" % [temp_path, size])
	if size > MAX_SCREENSHOT_SIZE:
		label.text = "Screenshot is too large (max %d MB).\nPlease select a smaller file." % MAX_SCREENSHOT_SIZE_MB
		#accept_dialog.popup_centered()
		return
	uploader.text = temp_path
	var image = Image.new()
	var err = image.load(temp_path)
	print("Image load error code: %d" % err)
	if err == OK:
		var tex = ImageTexture.create_from_image(image)
		ss_preview.texture = tex
	print("Picked file temporary path: " + temp_path)
	print("Picked file mime type: " + mime_type)
	# If you want to delete the temp file when done: ◑﹏◐
	# DirAccess.remove_absolute(temp_path)

func _style_popup(popup: PopupMenu) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = "#efefef"
	popup.add_theme_stylebox_override("panel", style)
	popup.add_theme_font_override("font", BASIS_33)
	popup.add_theme_font_size_override("font_size", 28)
	popup.add_theme_color_override("font_color", "#181818")
	popup.add_theme_color_override("font_hover_color", Color.YELLOW)
	popup.max_size = Vector2(200, 200)

func _on_submit_pressed() -> void:
	_show_confirm_dialog("submit")

func _on_clear_pressed() -> void:
	_show_confirm_dialog("clear")

func _show_confirm_dialog(action: String):
	pending_action = action
	if action == "submit":
		if text_edit.text == "" or text_edit.text.is_empty():
			empty_dialog1.show()
			return
		_show_submit_confirm_dialog("submit", "Are you sure you want to submit this report?")
	elif action == "clear":
		_show_clear_confirm_dialog("clear", "Are you sure you want to clear this report?")
	elif action == "exit":
		if text_edit.text != "":
			_show_exit_confirm_dialog("exit", "Exiting will discard the report.")
		else:
			SignalBus.exit_overlay.emit()
			queue_free()

func _show_submit_confirm_dialog(action: String, text: String):
	pending_action = action
	submit_confirmation.show()
	window1.show()
	label2.text = text

func _show_clear_confirm_dialog(action: String, text: String):
	pending_action = action
	clear_confirmation.show()
	window2.show()
	label3.text = text

func _show_exit_confirm_dialog(action: String, text: String):
	pending_action = action
	exit_confirmation.show()
	window3.show()
	label4.text = text
	
#func _dialog_config(action: String, text: String):
	 #pending_action = action
	#label2.text = text
	#confirmation_dialog.popup_centered()

func _on_confirmation_dialog_confirmed() -> void:
	_confirm_action()

func _confirm_action() -> void:
	if pending_action == "submit":
		menu_loading_screen.show()
		_submit_bug_report()
	elif pending_action == "clear":
		_clear_report_fields()
	elif pending_action == "exit":
		if text_edit.text != "":
			SignalBus.exit_overlay.emit()
			queue_free()

func _clear_report_fields() -> void:
	clear_confirmation.hide()
	window2.hide()
	text_edit.text = ""
	bug_type.select(0)
	ss_preview.texture = null
	uploader.text = ""

# BUG REPORT SUBMISSION
func _submit_bug_report():
	submit_confirmation.hide()
	window1.hide()
	var user_name = Session.username
	if user_name == "":
		user_name = "Anonymous"

	var bug = bug_type.get_item_text(bug_type.selected)
	var message = text_edit.text
	var screenshot_path = uploader.text

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(Callable(self, "_on_request_completed"))

	var form = {
		"user": user_name,
		"bug_type": bug,
		"message": message
	}

	var boundary = "----GodotBoundary" + str(randi())
	var body = _create_multipart_form(form, screenshot_path, boundary)
	var headers = ["Content-Type: multipart/form-data; boundary=" + boundary]

	http.request_raw("https://requestmessage-admin.onrender.com/api/submit_bug.php", headers, HTTPClient.METHOD_POST, body)

func _create_multipart_form(fields: Dictionary, file_path: String, boundary: String) -> PackedByteArray:
	var body = PackedByteArray()
	for key in fields.keys():
		body.append_array(("--%s\r\n" % boundary).to_utf8_buffer())
		body.append_array(("Content-Disposition: form-data; name=\"%s\"\r\n\r\n" % key).to_utf8_buffer())
		body.append_array((str(fields[key]) + "\r\n").to_utf8_buffer())
	if file_path != "":
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var file_name = file_path.get_file()
			var file_data = file.get_buffer(file.get_length())
			file.close()
			body.append_array(("--%s\r\n" % boundary).to_utf8_buffer())
			body.append_array(("Content-Disposition: form-data; name=\"screenshot\"; filename=\"%s\"\r\n" % file_name).to_utf8_buffer())
			body.append_array("Content-Type: image/png\r\n\r\n".to_utf8_buffer())
			body.append_array(file_data)
			body.append_array("\r\n".to_utf8_buffer())
	body.append_array(("--%s--\r\n" % boundary).to_utf8_buffer())
	return body

func _on_request_completed(result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var response_text = body.get_string_from_utf8()
	print("Server response: ", response_text)

	if response_code != 200:
		print("Server error: ", response_code)
		return

	var parse_result = JSON.parse_string(response_text)
	if typeof(parse_result) != TYPE_DICTIONARY:
		print("Invalid JSON response")
		return

	if parse_result.get("status", "") == "success":
		print("Bug report submitted successfully!")
		_clear_report_fields()
	else:
		print("Error submitting bug report: ", parse_result.get("message", "Unknown error"))
	_report_feedback_success_or_not(response_code)

func _report_feedback_success_or_not(res_code: int)->void:
	if res_code != 200:
		label.text = "An error occured when trying to submit your report, please try again later."
	else:
		label.text = "Your report was successfully submitted."
	accept_dialog1.show()
	menu_loading_screen.hide()

func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")

func _on_back_pressed():
	_show_confirm_dialog("exit")
	#SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")

func _on_yes_button3_pressed():
	SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")

func _on_btn_ok_pressed():
	empty_dialog1.hide()
	
func _on_btn_ok1_pressed():
	accept_dialog1.hide()

func _on_cancel_pressed():
	submit_confirmation.hide()
	window1.hide()
	clear_confirmation.hide()
	window2.hide()
	exit_confirmation.hide()
	window3.hide()
