extends Control

@onready var new_game: Button = $options_holder/new_game
@onready var load_game: Button = $options_holder/load_game
@onready var report_bug: Button = $options_holder/report_bug
@onready var credits: Button = $options_holder/credits
@onready var o_options: Button = $options_holder/options
@onready var exit: Button = $options_holder/exit

@onready var overlayer: Control = $overlayer
@onready var options: VBoxContainer = $options_holder

var current_choice = 0

func _ready() -> void:
	var options_menu = options.get_children()
	options_menu[current_choice].grab_focus()
	
	SignalBus.exit_overlay.connect(_exit_overlay)
	
	for option in options_menu:
		option.mouse_entered.connect(_option_hover.bind(option))

func _option_hover(option: Button) -> void:
	current_choice = options.get_children().find(option)
	option.grab_focus()

func _on_new_game_pressed() -> void:
	if BgmManager:
		BgmManager.stop_music()
	SignalBus.next_scene.emit("res://scenes/game/act_1/scene_1/act_1_scene_1.tscn")

func _on_load_game_pressed() -> void:
	if BgmManager:
		BgmManager.stop_music()
	print("load game")

func _on_report_bug_pressed() -> void:
	_option_overlayer("res://scenes/menu/menu_report_a_bug.tscn")
	current_choice = options.get_children().find(report_bug)

func _on_credits_pressed() -> void:
	print("credits")
	_option_overlayer("res://scenes/menu/menu_credits.tscn")
	current_choice = options.get_children().find(credits)

func _on_options_pressed() -> void:
	print("options")
	_option_overlayer("res://scenes/menu/menu_game_settings.tscn")
	current_choice = options.get_children().find(o_options)

func _on_exit_pressed() -> void:
	print("exit")
	get_tree().quit()

func _option_overlayer(path: String) -> void:
	for child in overlayer.get_children():
		child.queue_free()
	
	var settings := load(path)
	var settings_instance = settings.instantiate()
	
	overlayer.add_child(settings_instance)
	overlayer.visible = true

func _exit_overlay() -> void:
	overlayer.visible = false
	options.get_children()[current_choice].grab_focus()
