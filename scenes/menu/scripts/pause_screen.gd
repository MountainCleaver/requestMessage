extends Control

@onready var continue_option: Button = $VBoxContainer/continue
@onready var settings: Button = $VBoxContainer/settings
@onready var exit_to_main_menu: Button = $VBoxContainer/exit_to_main_menu
@onready var overlayer: Control = $overlayer
@onready var exitToMenu_confirmation: Control = $ExitToMenuConfirmation
@onready var window: Window = $ExitToMenuConfirmation/Window


var dialog_showing : bool = false
var in_overlay : bool = false

var previous_focus: Control = null

func _ready() -> void:
	SignalBus.exit_overlay.connect(_exit_overlay)
	SignalBus.brightness_changed.connect(_on_brightness_changed)
	hide()

func _input(event: InputEvent) -> void:
	var network = get_node_or_null("/root/NetworkStatus")
	if network and network.is_network_blocked:
		return

	if event.is_action_pressed("escape") and not get_tree().paused:
		show_pause_screen()
	elif event.is_action_pressed("escape") and get_tree().paused and not in_overlay:
		hide_pause_screen()

func show_pause_screen():
	previous_focus = get_viewport().gui_get_focus_owner()
	show()
	get_tree().paused = true
	continue_option.grab_focus()
	BrightnessManager.set_brightness(Settings.settings.brightness)

func hide_pause_screen():
	get_viewport().gui_release_focus()
	hide()
	get_tree().paused = false
	if previous_focus != null and is_instance_valid(previous_focus):
		print("Restoring focus to: ", previous_focus)
		previous_focus.call_deferred("grab_focus")
	else:
		print("No previous focus to restore")
	previous_focus = null

func _on_continue_pressed() -> void:
	hide_pause_screen()

func _on_settings_pressed() -> void:
	in_overlay = true
	_option_overlayer("res://scenes/menu/pause_screen_settings.tscn")

func _on_exit_to_main_menu_pressed() -> void:
	if exitToMenu_confirmation.visible:
		return  # Already showing, ignore extra clicks

	exitToMenu_confirmation.show()
	window.show()
	dialog_showing = true


func _on_exit_main_menu_dialog_confirmed() -> void:
	# Clean phone screens
	if Hud.has_node("Control/phone/MarginContainer"):
		var phone_margin_container = Hud.get_node("Control/phone/MarginContainer")
		for node in phone_margin_container.get_children():
			if node.name != "lock_screen":
				node.queue_free()

	if Hud.has_node("Control/phone"):
		var phone_node = Hud.get_node("Control/phone")
		phone_node.visible = false

	# Clean objectives
	if Hud.objectives_panel.visible or ObjectiveManager.objectives:
		ObjectiveManager.empty_objectives()
		Hud.hide_objectives()
		Hud.clear_objectives()

	# Hide any popups
	if Hud.popup_showing:
		Hud.hide_popup()

	# Hide pause screen and go to main menu
	hide_pause_screen()

	# Emit scene change signal
	SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")


func _on_brightness_changed(value: float) -> void:
	BrightnessManager.set_brightness(value)

func _on_exit_main_menu_dialog_canceled() -> void:
	pass

func _option_overlayer(path: String) -> void:
	for child in overlayer.get_children():
		child.queue_free()
	var settings = load(path)
	var settings_instance = settings.instantiate()
	overlayer.add_child(settings_instance)
	overlayer.visible = true

func _exit_overlay() -> void:
	in_overlay = false
	continue_option.grab_focus()
	overlayer.visible = false
		
func on_internet_status_changed(has_internet: bool) -> void:
	if has_internet:
		pass
	else:
		print("No internet here, show warning or disable buttons.")
