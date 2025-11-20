extends Control

# ============================================================
#  NODES
# ============================================================
@onready var exit: Button = %exit
@onready var uploader: Button = $Panel/HBoxContainer/SCREENSHOT/UPLOADER
@onready var file_dialog: FileDialog = $Panel/HBoxContainer/SCREENSHOT/UPLOADER/FileDialog
@onready var ss_preview: TextureRect = $Panel/ss_preview
@onready var bug_type: OptionButton = $Panel/HBoxContainer/BUG_TYPE/BUG_TYPE
@onready var text_edit: TextEdit = $Panel/TextEdit
@onready var submit: Button = $Panel/BUTTONS/SUBMIT
@onready var clear: Button = $Panel/BUTTONS/CLEAR
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog
@onready var menu_loading_screen: CanvasLayer = $menu_loading_screen
@onready var accept_dialog: AcceptDialog = $AcceptDialog
@onready var empty_dialog: AcceptDialog = $EmptyDialog

const BASIS_33 = preload("res://assets/fonts/basis33.ttf")
@onready var bug_type_popup = bug_type.get_popup()
var pending_action: String = ""

# ============================================================
#  FILE UPLOAD STATE
# ============================================================
var uploaded_base64: String = ""
var uploaded_filename: String = ""
var uploaded_mime: String = ""

# ============================================================
#  READY
# ============================================================
func _ready() -> void:
	accept_dialog.hide()
	menu_loading_screen.hide()
	empty_dialog.hide()
	file_dialog.filters = ["*.png ; PNG Images", "*.jpg ; JPEG Images"]
	file_dialog.file_selected.connect(Callable(self, "_on_file_selected"))
	_style_popup(bug_type_popup)

	# Initialize web polling ONLY if on Web
	if OS.has_feature("web"):
		_init_web_polling()

# ============================================================
#  INPUT / EXIT
# ============================================================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_show_confirm_dialog("exit")

func _on_exit_pressed() -> void:
	_show_confirm_dialog("exit")

# ============================================================
#  UPLOADER BUTTON
# ============================================================
func _on_uploader_pressed() -> void:
	if OS.has_feature("web"):
		print("[web] uploader pressed -> opening browser picker")
		_trigger_browser_file_picker("image/png,image/jpeg")
	else:
		file_dialog.visible = true

# ============================================================
#  DESKTOP UPLOADER (FileDialog)
# ============================================================
func _on_file_selected(path: String) -> void:
	print("[desktop] file selected:", path)
	uploader.text = path

	var image := Image.load_from_file(path)
	if image and not image.is_empty():
		ss_preview.texture = ImageTexture.create_from_image(image)
	else:
		print("[desktop] failed to load file:", path)

# ============================================================
#  POPUP STYLE
# ============================================================
func _style_popup(popup: PopupMenu) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = "#efefef"
	popup.add_theme_stylebox_override("panel", style)
	popup.add_theme_font_override("font", BASIS_33)
	popup.add_theme_font_size_override("font_size", 28)
	popup.add_theme_color_override("font_color", "#181818")
	popup.add_theme_color_override("font_hover_color", Color.YELLOW)
	popup.max_size = Vector2(200, 200)

# ============================================================
#  BUTTON HANDLERS
# ============================================================
func _on_submit_pressed() -> void:
	_show_confirm_dialog("submit")

func _on_clear_pressed() -> void:
	_show_confirm_dialog("clear")

# ============================================================
#  CONFIRMATION DIALOG
# ============================================================
func _show_confirm_dialog(action: String):
	pending_action = action
	if action == "submit":
		if text_edit.text == "":
			empty_dialog.show()
			return
		_dialog_config("submit", "Are you sure you want to submit this report?")
	elif action == "clear":
		_dialog_config("clear", "Are you sure you want to clear this report?")
	elif action == "exit":
		if text_edit.text != "":
			_dialog_config("exit", "Exiting will discard the report.")
		else:
			SignalBus.exit_overlay.emit()
			queue_free()

func _dialog_config(action: String, dialog_text: String):
	pending_action = action
	confirmation_dialog.dialog_text = dialog_text
	confirmation_dialog.popup_centered()

func _on_confirmation_dialog_confirmed() -> void:
	_confirm_action()

func _confirm_action() -> void:
	if pending_action == "submit":
		menu_loading_screen.show()
		_submit_bug_report()
	elif pending_action == "clear":
		_clear_report_fields()
	elif pending_action == "exit":
		SignalBus.exit_overlay.emit()
		queue_free()

func _clear_report_fields() -> void:
	text_edit.text = ""
	bug_type.select(0)
	ss_preview.texture = null
	uploader.text = ""
	uploaded_base64 = ""
	uploaded_filename = ""
	uploaded_mime = ""

# ============================================================
#  SUBMIT BUG REPORT
# ============================================================
func _submit_bug_report():
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

	# Web (base64 upload)
	if OS.has_feature("web") and uploaded_base64 != "":
		var file_bytes = Marshalls.base64_to_raw(uploaded_base64)
		var file_name = uploaded_filename if uploaded_filename != "" else "screenshot.png"
		var mime = uploaded_mime if uploaded_mime != "" else "image/png"

		var body = _create_multipart_form_with_bytes(form, file_bytes, file_name, mime, boundary)
		var headers = ["Content-Type: multipart/form-data; boundary=" + boundary]

		http.request_raw("https://requestmessage-admin.onrender.com/api/submit_bug.php",
			headers, HTTPClient.METHOD_POST, body)

	# Desktop upload
	else:
		var body = _create_multipart_form(form, screenshot_path, boundary)
		var headers = ["Content-Type: multipart/form-data; boundary=" + boundary]

		http.request_raw("https://requestmessage-admin.onrender.com/api/submit_bug.php",
			headers, HTTPClient.METHOD_POST, body)

# ============================================================
#  MULTIPART HELPERS
# ============================================================
func _create_multipart_form_with_bytes(fields, file_bytes, file_name, mime, boundary) -> PackedByteArray:
	var body = PackedByteArray()

	for key in fields.keys():
		body.append_array(("--%s\r\n" % boundary).to_utf8_buffer())
		body.append_array(("Content-Disposition: form-data; name=\"%s\"\r\n\r\n" % key).to_utf8_buffer())
		body.append_array((str(fields[key]) + "\r\n").to_utf8_buffer())

	if file_bytes.size() > 0:
		body.append_array(("--%s\r\n" % boundary).to_utf8_buffer())
		body.append_array(("Content-Disposition: form-data; name=\"screenshot\"; filename=\"%s\"\r\n" % file_name).to_utf8_buffer())
		body.append_array(("Content-Type: %s\r\n\r\n" % mime).to_utf8_buffer())
		body.append_array(file_bytes)
		body.append_array("\r\n".to_utf8_buffer())

	body.append_array(("--%s--\r\n" % boundary).to_utf8_buffer())
	return body

func _create_multipart_form(fields, file_path, boundary) -> PackedByteArray:
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

			body.append_array(("--%s\r\n" % boundary).to_utf8_buffer())
			body.append_array(("Content-Disposition: form-data; name=\"screenshot\"; filename=\"%s\"\r\n" % file_name).to_utf8_buffer())
			body.append_array("Content-Type: image/png\r\n\r\n".to_utf8_buffer())
			body.append_array(file_data)
			body.append_array("\r\n".to_utf8_buffer())

	body.append_array(("--%s--\r\n" % boundary).to_utf8_buffer())
	return body

# ============================================================
#  HTTP CALLBACK
# ============================================================
func _on_request_completed(result, response_code, headers, body):
	var text = body.get_string_from_utf8()
	print("Server response:", text)

	if response_code != 200:
		print("Server error:", response_code)
	else:
		var parsed = JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY and parsed.get("status", "") == "success":
			_clear_report_fields()

	_report_feedback_success_or_not(response_code)

func _report_feedback_success_or_not(res_code: int) -> void:
	if res_code != 200:
		accept_dialog.dialog_text = "An error occurred when trying to submit your report."
	else:
		accept_dialog.dialog_text = "Your report was successfully submitted."

	accept_dialog.show()
	menu_loading_screen.hide()

func on_internet_status_changed(has_internet: bool) -> void:
	if not has_internet:
		print("No internet available.")

# ============================================================
#  WEB UPLOADER (MOVED TO BOTTOM)
# ============================================================

# Called in _ready()
func _init_web_polling() -> void:
	JavaScriptBridge.eval("""
		window.__upload_cache = { ready:false, data:"", name:"", type:"" };
	""")
	set_process(true)

func _process(delta: float) -> void:
	if not OS.has_feature("web"):
		return

	var ready: bool = JavaScriptBridge.eval("window.__upload_cache.ready")
	if ready:
		var data = JavaScriptBridge.eval("window.__upload_cache.data")
		var name = JavaScriptBridge.eval("window.__upload_cache.name")
		var mime = JavaScriptBridge.eval("window.__upload_cache.type")

		JavaScriptBridge.eval("window.__upload_cache.ready = false")
		_on_web_file_loaded(data, name, mime)

func _trigger_browser_file_picker(accept_types: String) -> void:
	var js := """
	(function() {
		let input = document.createElement('input');
		input.type = 'file';
		input.accept = '%s';

		input.onchange = (e) => {
			let file = e.target.files[0];
			if (!file) return;

			let reader = new FileReader();

			reader.onload = (ev) => {
				window.__upload_cache.data = ev.target.result;
				window.__upload_cache.name = file.name;
				window.__upload_cache.type = file.type;
				window.__upload_cache.ready = true;
			};

			reader.readAsDataURL(file);
		};

		input.click();
	})();
	""" % accept_types

	JavaScriptBridge.eval(js, true)

func _on_web_file_loaded(data_url: String, name: String, mime: String) -> void:
	print("[web] File received:", name)

	uploaded_filename = name
	uploaded_mime = mime

	var comma := data_url.find(",")
	uploaded_base64 = data_url.substr(comma + 1)

	uploader.text = name

	var raw := Marshalls.base64_to_raw(uploaded_base64)
	var img := Image.new()

	var err := (
		img.load_png_from_buffer(raw)
		if mime == "image/png"
		else img.load_jpg_from_buffer(raw)
	)

	if err == OK:
		ss_preview.texture = ImageTexture.create_from_image(img)
		print("[web] Preview OK")
	else:
		print("[web] Preview FAILED")
