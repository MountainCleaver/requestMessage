extends Control

@onready var continue_option: Button = $VBoxContainer/continue
@onready var settings: Button = $VBoxContainer/settings
@onready var exit_to_main_menu: Button = $VBoxContainer/exit_to_main_menu

@onready var exit_main_menu_dialog: ConfirmationDialog = $exit_main_menu_dialog

@onready var overlayer: Control = $overlayer

var dialog_showing : bool = false;
var in_overlay : bool = false;

var previous_focus: Control = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.exit_overlay.connect(_exit_overlay)
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape") and not get_tree().paused:
		show_pause_screen();
	elif event.is_action_pressed("escape") and get_tree().paused and not in_overlay:
		hide_pause_screen();

func show_pause_screen():
	# Store what currently has focus BEFORE we take it
	previous_focus = get_viewport().gui_get_focus_owner()
	
	show()
	get_tree().paused = true
	continue_option.grab_focus()

func hide_pause_screen():
	get_viewport().gui_release_focus()
	hide()
	get_tree().paused = false
	
	# Restore focus to whatever had it before
	if previous_focus != null and is_instance_valid(previous_focus):
		print("Restoring focus to: ", previous_focus)
		previous_focus.call_deferred("grab_focus")
	else:
		print("No previous focus to restore")
	
	previous_focus = null

func _on_continue_pressed() -> void:
	hide()
	get_tree().paused = false
	pass # Replace with function body.

func _on_settings_pressed() -> void:
	in_overlay = true;
	_option_overlayer("res://scenes/menu/pause_screen_settings.tscn")

func _on_exit_to_main_menu_pressed() -> void:
	if not dialog_showing:
		exit_main_menu_dialog.show();
		dialog_showing = true;
	else:
		dialog_showing = false;
		exit_main_menu_dialog.hide();


func _on_exit_main_menu_dialog_confirmed() -> void:
	# clean phone screens
	if Hud.has_node("Control/phone/MarginContainer"):
		var phone_margin_container = Hud.get_node("Control/phone/MarginContainer")
		for node in phone_margin_container.get_children():
			if node.name != "lock_screen":
				node.queue_free()

	# UPDATE: FIXED BY HIDING NA LANG   ||   shit aint working, cant fix it :( 
	if Hud.has_node("Control/phone"):
		var phone_node = Hud.get_node("Control/phone")
		phone_node.visible = false

	# clean objectives
	if Hud.objectives_panel.visible or ObjectiveManager.objectives:
		ObjectiveManager.empty_objectives()
		Hud.hide_objectives()
		Hud.clear_objectives()

	# hide any popups
	if Hud.popup_showing:
		Hud.hide_popup()

	# hide pause screen and go to main menu
	hide_pause_screen()
	SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")

	



func _on_exit_main_menu_dialog_canceled() -> void:
	pass # Replace with function body.
	
func _option_overlayer(path: String) -> void:
	for child in overlayer.get_children():
		child.queue_free()
	var settings = load(path)
	var settings_instance = settings.instantiate()
	overlayer.add_child(settings_instance)
	overlayer.visible = true
	
func _exit_overlay() -> void:
	in_overlay = false;
	continue_option.grab_focus();
	overlayer.visible = false
