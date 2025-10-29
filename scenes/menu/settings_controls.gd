extends Control

@onready var action_container: VBoxContainer = $HBoxContainer/ScrollContainer/action_container
const KEY_BIND_SETTING = preload("uid://camvb45ixm320")
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog

var is_remapping: bool = false
var action_to_remap = null
var remapping_button = null

var previous_key_text: String = ""

var input_actions: Dictionary = {
	"arrow_up": "Move Up",
	"arrow_down": "Move Down",
	"arrow_left": "Move Left",
	"arrow_right": "Move Right",
	"run": "Run",
	"dialog_next": "Next Dialogue",
	"map": "Map",
	"flashlight": "Flashlight"
}


func _ready() -> void:
	confirmation_dialog.hide()
	_create_action_list()


# ==========================================================
# 🔹 PERSISTENCE FUNCTIONS
# ==========================================================


func _save_keybind(action: String, event: InputEvent) -> void:
	var ev_dict = _event_to_dict(event)
	Settings.settings.key_bindings[action] = ev_dict
	Settings.save_settings()


func _event_to_dict(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key",
			"physical_keycode": event.physical_keycode,
			"unicode": event.unicode
		}
	return {}


func _create_action_list() -> void:
	for item in action_container.get_children():
		item.queue_free()
	
	for action in input_actions.keys():
		var button = KEY_BIND_SETTING.instantiate()
		var action_label = button.find_child("label_action")
		var input_label = button.find_child("label_input")
		
		action_label.text = input_actions[action]
		
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			input_label.text = "(Empty)"
		
		action_container.add_child(button)
		button.pressed.connect(_on_input_button_pressed.bind(button, action))


func _on_input_button_pressed(button: Button, action: String) -> void:
	if not is_remapping:
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		
		previous_key_text = button.find_child("label_input").text
		button.find_child("label_input").text = "Press new key..."


func _input(event: InputEvent) -> void:
	if not is_remapping:
		return

	if event is InputEventMouse:
		return
	if not (event is InputEventKey and event.pressed):
		return
	if event.echo:
		return

	var ignored_keys = [
		KEY_ESCAPE, # for pause
		KEY_SPACE, # can interfere with UI
		KEY_ENTER, # can also interfere with UI
		KEY_KP_ENTER, # can also also interfere with UI
		KEY_E # for interact
	]
	
	if event.physical_keycode in ignored_keys:
		_show_temp_label("Invalid key", Color.RED)
		return

	# check duplicate
	for act in input_actions.keys():
		if act == action_to_remap:
			continue
		for e in InputMap.action_get_events(act):
			if e is InputEventKey and e.physical_keycode == event.physical_keycode:
				_show_temp_label("Already used", Color.RED)
				return
	
	InputMap.action_erase_events(action_to_remap)
	InputMap.action_add_event(action_to_remap, event)
	_update_action_list(remapping_button, event)
	_save_keybind(action_to_remap, event)

	is_remapping = false
	action_to_remap = null
	remapping_button = null
	accept_event()


func _show_temp_label(text: String, color: Color) -> void:
	var label = remapping_button.find_child("label_input")
	label.text = text
	label.add_theme_color_override("font_color", color)
	await get_tree().create_timer(0.5).timeout
	label.text = previous_key_text
	label.remove_theme_color_override("font_color")
	is_remapping = false


func _update_action_list(button: Button, event: InputEvent) -> void:
	button.find_child("label_input").text = event.as_text().trim_suffix(" (Physical)")

func _on_restore_default_btn_pressed() -> void:
	confirmation_dialog.show()

func _on_confirmation_dialog_confirmed() -> void:
	InputMap.load_from_project_settings()
	Settings.settings.key_bindings.clear()
	Settings.save_settings()
	_create_action_list()
