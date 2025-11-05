extends Control

signal internet_status_changed(has_internet: bool)

# UI Nodes
@onready var loading_screen: CanvasLayer = $menu_loading_screen
@onready var loading_label: Label = $menu_loading_screen/Label
@onready var color_rect: ColorRect = $menu_loading_screen/ColorRect
@onready var connection_label: Label = $menu_loading_screen/ConnectionLabel
@onready var reconnect_button: Button = $menu_loading_screen/Reconnect
@onready var http_request: HTTPRequest = $HTTPRequest

# Timers (must exist in scene tree!)
@onready var internet_check_timer: Timer = $internet_check_timer
@onready var connection_label_timer: Timer = $connection_label_timer
@onready var fade_timer: Timer = $fade_timer

# Variables
var has_internet: bool = false
var checking: bool = false
var waiting_for_reconnect: bool = false

func _ready() -> void:
	# Connect button
	reconnect_button.pressed.connect(Callable(self, "_on_reconnect_pressed"))
	_hide_loading_ui()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	# Connect timers using Callable
	if not internet_check_timer.is_connected("timeout", Callable(self, "check_internet_connection")):
		internet_check_timer.connect("timeout", Callable(self, "check_internet_connection"))
		internet_check_timer.start()

	if not connection_label_timer.is_connected("timeout", Callable(self, "_show_connection_label")):
		connection_label_timer.connect("timeout", Callable(self, "_show_connection_label"))

	if not fade_timer.is_connected("timeout", Callable(self, "_hide_loading_ui")):
		fade_timer.connect("timeout", Callable(self, "_hide_loading_ui"))

	# Timer properties (optional if already set in editor)
	internet_check_timer.wait_time = 1.0
	internet_check_timer.one_shot = false
	internet_check_timer.autostart = true
	internet_check_timer.process_mode = Node.PROCESS_MODE_ALWAYS  # keep checking even if game paused

	connection_label_timer.wait_time = 5.0
	connection_label_timer.one_shot = true
	connection_label_timer.process_mode = Node.PROCESS_MODE_ALWAYS  # show label even if paused

	fade_timer.wait_time = 1.5
	fade_timer.one_shot = true
	fade_timer.process_mode = Node.PROCESS_MODE_ALWAYS  # fade out UI even if paused

	http_request.timeout = 3.0
	http_request.request_completed.connect(_on_http_request_completed)
	http_request.process_mode = Node.PROCESS_MODE_ALWAYS
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
		if waiting_for_reconnect or loading_screen.visible:
			has_internet = true
			waiting_for_reconnect = false
			_show_reconnected_label() 
		else:
			has_internet = true
			waiting_for_reconnect = false
			_hide_loading_ui()  
	else:
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

	# Show loading UI
	loading_screen.visible = true
	color_rect.visible = true
	loading_label.visible = true
	connection_label.visible = false
	reconnect_button.visible = false

	# PAUSE GAME
	get_tree().paused = true

	# Ensure UI nodes still process input
	loading_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	color_rect.process_mode = Node.PROCESS_MODE_ALWAYS
	loading_label.process_mode = Node.PROCESS_MODE_ALWAYS
	connection_label.process_mode = Node.PROCESS_MODE_ALWAYS
	reconnect_button.process_mode = Node.PROCESS_MODE_ALWAYS

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

	# UNPAUSE GAME so gameplay resumes
	get_tree().paused = false


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
