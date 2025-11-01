extends Control

@onready var action_container: VBoxContainer = $HBoxContainer/VBoxContainer
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog

# The single pre-made template row
@onready var template_row: HBoxContainer = $HBoxContainer/VBoxContainer/HBoxContainer
@onready var template_label: Label = template_row.get_node("Label")
@onready var template_button: Button = template_row.get_node("Button")

var is_remapping: bool = false
var action_to_remap: String = ""
var remapping_button: Button = null
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

var button_action_map: Dictionary = {}

func _ready() -> void:
	confirmation_dialog.hide()
	confirmation_dialog.connect("confirmed", Callable(self, "_on_confirmation_dialog_confirmed"))
	_create_action_list()


func _create_action_list() -> void:
	# Clear previous children except the template
	for child in action_container.get_children():
		if child != template_row:
			child.queue_free()
	
	template_row.hide() # hide template

	# Create a row for each action
	for action_name in input_actions.keys():
		var row = template_row.duplicate() as HBoxContainer
		row.show()
		var label = row.get_node("Label") as Label
		var button = row.get_node("Button") as Button

		label.text = input_actions[action_name]

		# Set button text from InputMap
		var events = InputMap.action_get_events(action_name)
		if events.size() > 0:
			button.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			button.text = "(Empty)"

		# Connect the button
		button.connect("pressed", Callable(self, "_on_input_button_pressed").bind(button, action_name))

		action_container.add_child(row)
		button_action_map[button] = action_name

	# Add Restore Defaults button at the bottom
	var restore_btn = Button.new()
	restore_btn.text = "Restore Defaults"
	restore_btn.connect("pressed", Callable(self, "_on_restore_default_btn_pressed"))
	action_container.add_child(restore_btn)



# =========================
# BUTTON PRESS HANDLER
# =========================
func _on_input_button_pressed(button: Button, action_name: String) -> void:
	if is_remapping:
		return

	is_remapping = true
	action_to_remap = action_name
	remapping_button = button
	previous_key_text = button.text
	button.text = "Press new key..."

# =========================
# INPUT HANDLER
# =========================
func _input(event: InputEvent) -> void:
	if not is_remapping:
		return
	if event is InputEventMouse:
		return
	if not (event is InputEventKey and event.pressed):
		return
	if event.echo:
		return

	var ignored_keys = [KEY_ESCAPE, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]
	if event.physical_keycode in ignored_keys:
		_show_temp_label("Invalid key", Color.RED)
		return

	# Check duplicate keys
	for act in input_actions.keys():
		if act == action_to_remap:
			continue
		for e in InputMap.action_get_events(act):
			if e is InputEventKey and e.physical_keycode == event.physical_keycode:
				_show_temp_label("Already used", Color.RED)
				return

	# Update InputMap
	InputMap.action_erase_events(action_to_remap)
	InputMap.action_add_event(action_to_remap, event)
	remapping_button.text = event.as_text().trim_suffix(" (Physical)")
	_save_keybind(action_to_remap, event)

	# Reset remapping state
	is_remapping = false
	action_to_remap = ""
	remapping_button = null
	accept_event()

# =========================
# TEMP LABEL FEEDBACK
# =========================
func _show_temp_label(text: String, color: Color) -> void:
	remapping_button.text = text
	remapping_button.add_theme_color_override("font_color", color)
	await get_tree().create_timer(0.5).timeout
	remapping_button.text = previous_key_text
	remapping_button.remove_theme_color_override("font_color")
	is_remapping = false

# =========================
# SAVE KEYBIND
# =========================
func _save_keybind(action: String, event: InputEvent) -> void:
	var ev_dict = {}
	if event is InputEventKey:
		ev_dict = {
			"type": "key",
			"physical_keycode": event.physical_keycode,
			"unicode": event.unicode
		}
	Settings.settings.key_bindings[action] = ev_dict
	Settings.save_settings()

	var hud := _find_hud(get_tree().current_scene)
	if hud and hud.has_method("_update_guide_keys"):
		hud._update_guide_keys()

func _find_hud(node: Node) -> CanvasLayer:
	if node.name == "explorer_hud" and node is CanvasLayer:
		return node
	for child in node.get_children():
		if child is Node:
			var result := _find_hud(child)
			if result:
				return result
	return null

# =========================
# RESTORE DEFAULTS
# =========================
func _on_restore_default_btn_pressed() -> void:
	confirmation_dialog.show()

func _on_confirmation_dialog_confirmed() -> void:
	InputMap.load_from_project_settings()
	Settings.settings.key_bindings.clear()
	Settings.save_settings()
	_create_action_list()

	var hud := _find_hud(get_tree().current_scene)
	if hud and hud.has_method("_update_guide_keys"):
		hud._update_guide_keys()
