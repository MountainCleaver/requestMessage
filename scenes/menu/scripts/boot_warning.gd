extends Control

@onready var splash_title: RichTextLabel = $splash_title
@onready var title_game: RichTextLabel = $title_game
@onready var warning_holder: Panel = $warning_holder
@onready var proceed: Panel = $proceed
@onready var button: Button = $proceed/Button
@onready var click: AudioStreamPlayer = $click
@onready var connection_label: Label = $ConnectionLabel


var loading_screen_scene: PackedScene
var loading_screen_instance: CanvasLayer = null

var logged_in: bool = false
var has_internet: bool = false

var fade_time := 1.0
var display_time := 2.0

var base_position_splash: Vector2
var motion_seed_splash: float
var time_acc: float = 0.0

func _ready() -> void:
	# Initial visibility - hide everything at start
	splash_title.modulate.a = 0
	title_game.modulate.a = 0
	warning_holder.modulate.a = 0
	proceed.modulate.a = 0
	

	if connection_label:
		connection_label.visible = false
		connection_label.text = "Checking internet connection..."

	base_position_splash = splash_title.position
	motion_seed_splash = randf() * 10.0

	button.pressed.connect(_on_proceed_pressed)

	await get_tree().create_timer(0.5).timeout
	_check_internet_connection()

func _process(delta: float) -> void:
	time_acc += delta

	if has_internet and splash_title.modulate.a > 0:
		var angle = time_acc * 2.0 + motion_seed_splash
		var radius_x = 4 + sin(time_acc * 1.0 + motion_seed_splash) * 4
		var radius_y = 3 + cos(time_acc * 1.3 + motion_seed_splash * 1.5) * 3
		splash_title.position = base_position_splash + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)

func _check_internet_connection() -> void:
	if connection_label:
		connection_label.text = "Checking internet connection..."
		connection_label.visible = true
	
	# Brief pause to ensure user sees the message
	await get_tree().create_timer(0.5).timeout
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_http_request_completed)
	
	var error = http.request("https://www.google.com/generate_204")
	
	if error != OK:
		_show_connection_error()

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and (response_code >= 200 and response_code < 400 or response_code == 204):
		has_internet = true
		if connection_label:
			connection_label.visible = false
		_show_loading_screen()
	else:
		has_internet = false
		_show_connection_error()

func _show_loading_screen() -> void:
	loading_screen_scene = preload("res://scenes/menu/menu_loading_screen.tscn")
	loading_screen_instance = loading_screen_scene.instantiate()
	add_child(loading_screen_instance)
	
	var animation_player = loading_screen_instance.get_node("AnimationPlayer")
	if animation_player:
		animation_player.play("loading")  
	

	await get_tree().create_timer(1.0).timeout
	_start_splash_sequence()

func _hide_loading_screen() -> void:
	if loading_screen_instance:
		var animation_player = loading_screen_instance.get_node("AnimationPlayer")
		if animation_player:
			animation_player.stop()
		loading_screen_instance.queue_free()
		loading_screen_instance = null

func _show_connection_error() -> void:
	has_internet = false
	
	if connection_label:
		connection_label.text = "No internet connection!\nCheck your connection and restart the game"
		connection_label.visible = true
	
	button.disabled = true
	

func _start_splash_sequence() -> void:
	print("DEBUG: Starting splash sequence - Internet connection confirmed")
	
	_hide_loading_screen()
	
	var user_data: Dictionary = Session.get_user_info()
	logged_in = not user_data.is_empty()
	
	_fade_in_splash()

func _fade_in_splash() -> void:
	splash_title.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(splash_title, "modulate:a", 1, fade_time)
	tween.tween_callback(func() -> void:
		_on_fade_in_complete()
	)

func _on_fade_in_complete() -> void:
	await get_tree().create_timer(display_time).timeout
	_fade_out_splash()

func _fade_out_splash() -> void:
	var tween = create_tween()
	tween.tween_property(splash_title, "modulate:a", 0, fade_time)
	tween.tween_callback(func() -> void:
		_show_main_warning()
	)

func _show_main_warning() -> void:
	var tween = create_tween()
	tween.tween_property(title_game, "modulate:a", 1, fade_time)
	tween.tween_property(warning_holder, "modulate:a", 1, fade_time)
	tween.tween_property(proceed, "modulate:a", 1, fade_time)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("accept"):
		_go_next_scene()

func _on_proceed_pressed() -> void:
	if has_internet:
		_go_next_scene()

func _go_next_scene() -> void:
	if has_internet:
		if not logged_in:
			SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn")
		else:
			SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
