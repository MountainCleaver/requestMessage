extends Control

signal internet_status_changed(has_internet: bool)

# === UI Nodes ===
@onready var loading_screen: CanvasLayer = $menu_loading_screen
@onready var loading_label: Label = $menu_loading_screen/Label
@onready var color_rect: ColorRect = $menu_loading_screen/ColorRect
@onready var connection_label: Label = $menu_loading_screen/ConnectionLabel
@onready var reconnect_button: Button = $menu_loading_screen/Reconnect
@onready var http_request: HTTPRequest = $HTTPRequest

# === Variables ===
var has_internet: bool = false
var checking: bool = false
var waiting_for_reconnect: bool = false
var internet_check_timer: Timer
var connection_label_timer: Timer
var fade_timer: Timer

func _ready() -> void:
	reconnect_button.pressed.connect(_on_reconnect_pressed)
	_hide_loading_ui()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	internet_check_timer = Timer.new()
	internet_check_timer.wait_time = 1.0
	internet_check_timer.one_shot = false
	internet_check_timer.autostart = true
	internet_check_timer.timeout.connect(check_internet_connection)
	add_child(internet_check_timer)

	connection_label_timer = Timer.new()
	connection_label_timer.wait_time = 5.0
	connection_label_timer.one_shot = true
	connection_label_timer.timeout.connect(_show_connection_label)
	add_child(connection_label_timer)

	# Timer for fading out "Reconnected successfully"
	fade_timer = Timer.new()
	fade_timer.wait_time = 1.5 # how long the success label shows
	fade_timer.one_shot = true
	fade_timer.timeout.connect(_hide_loading_ui)
	add_child(fade_timer)

	http_request.timeout = 3.0
	http_request.request_completed.connect(_on_http_request_completed)

	check_internet_connection()


func check_internet_connection() -> void:
	if checking:
		return
	checking = true

	var err = http_request.request("https://www.google.com/generate_204")
	if err != OK:
		_on_connection_timeout()
		checking = false


func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	checking = false

	if result == HTTPRequest.RESULT_SUCCESS and (response_code >= 200 and response_code < 400 or response_code == 204):
		if not has_internet:
			print("[NetworkStatus] Internet restored")
			_show_reconnected_label()
		has_internet = true
		waiting_for_reconnect = false
		_notify_current_scene()
	else:
		if has_internet:
			print("[NetworkStatus] Internet lost")
		has_internet = false
		_on_connection_timeout()
		
	emit_signal("internet_status_changed", has_internet)


# === No internet / timeout ===
func _on_connection_timeout() -> void:
	if waiting_for_reconnect:
		return

	checking = false
	has_internet = false
	waiting_for_reconnect = true

	_notify_current_scene()
	emit_signal("internet_status_changed", has_internet)

	loading_screen.visible = true
	color_rect.visible = true
	loading_label.visible = true
	connection_label.visible = false
	reconnect_button.visible = false

	if connection_label_timer.is_stopped():
		connection_label_timer.start()


func _show_connection_label() -> void:
	loading_label.visible = false
	connection_label.text = "No internet connection!\nPlease check your connection."
	connection_label.visible = true
	reconnect_button.visible = true


# === Show Reconnected successfully before fade ===
func _show_reconnected_label() -> void:
	loading_screen.visible = true
	color_rect.visible = true
	loading_label.visible = false
	connection_label.text = "Reconnected successfully!"
	connection_label.visible = true
	reconnect_button.visible = false

	# Start fade timer
	if fade_timer.is_stopped():
		fade_timer.start()


# === Reconnect button pressed ===
func _on_reconnect_pressed() -> void:
	waiting_for_reconnect = false
	reconnect_button.visible = false
	loading_label.visible = true
	connection_label.visible = false
	loading_screen.visible = true
	color_rect.visible = true

	if connection_label_timer.is_stopped() == false:
		connection_label_timer.stop()

	check_internet_connection()


func _hide_loading_ui() -> void:
	loading_screen.visible = false
	loading_label.visible = false
	connection_label.visible = false
	reconnect_button.visible = false
	color_rect.visible = false


func _notify_current_scene() -> void:
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("on_internet_status_changed"):
		current_scene.call("on_internet_status_changed", has_internet)
