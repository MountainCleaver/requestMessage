extends Control

@onready var splash_title: RichTextLabel = $splash_title
@onready var title_game: RichTextLabel = $title_game
@onready var warning_holder: Panel = $warning_holder
@onready var proceed: Panel = $proceed
@onready var button: Button = $proceed/Button

var logged_in: bool = false

var fade_time := 1.0
var display_time := 2.0

# Motion variables (same behavior as intro_lines)
var base_position_splash: Vector2
var motion_seed_splash: float
var time_acc: float = 0.0

func _ready() -> void:
	# Initial visibility
	splash_title.modulate.a = 0
	title_game.modulate.a = 0
	warning_holder.modulate.a = 0
	proceed.modulate.a = 0

	base_position_splash = splash_title.position
	motion_seed_splash = randf() * 10.0

	var user_data: Dictionary = Session.get_user_info()
	logged_in = not user_data.is_empty()
	button.pressed.connect(_on_proceed_pressed)

	await get_tree().create_timer(0.5).timeout
	_fade_in_splash()

func _process(delta: float) -> void:
	time_acc += delta

	# floating motion for splash_title (like intro lines)
	if splash_title.modulate.a > 0:
		var angle = time_acc * 2.0 + motion_seed_splash
		var radius_x = 4 + sin(time_acc * 1.0 + motion_seed_splash) * 4
		var radius_y = 3 + cos(time_acc * 1.3 + motion_seed_splash * 1.5) * 3
		splash_title.position = base_position_splash + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)

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
	_go_next_scene()

func _go_next_scene() -> void:
	if not logged_in:
		SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn")
	else:
		SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
