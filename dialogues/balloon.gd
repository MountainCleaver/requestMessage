extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			queue_free()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

@onready var portrait: TextureRect = $Balloon/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/portrait
@onready var main_animation: AnimationPlayer = $main_animation

@onready var talk_sound: AudioStreamPlayer = $TalkSound

# === Flicker background reference ===
@onready var background_chat: PanelContainer = $Balloon/MarginContainer/PanelContainer

# === Flicker tween ===
var flicker_tween: Tween = null

@onready var next_indicators: MarginContainer = $Balloon/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DialogueLabel/next_indicators
@onready var next_label: Label = $Balloon/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DialogueLabel/next_indicators/HBoxContainer/next_label
@onready var next_icon: TextureRect = $Balloon/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DialogueLabel/next_indicators/HBoxContainer/next_icon


func _ready() -> void:
	next_indicators.hide()
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio = dialogue_label.visible_ratio
		self.dialogue_line = await resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	main_animation.play("dialogue_in")
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	next_indicators.hide()
	mutation_cooldown.stop()

	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	var raw_character_name = dialogue_line.character
	var display_name = raw_character_name

	# === AUTO FORMATTING ===
	if raw_character_name.to_lower() == "unknown_sender":
		display_name = "Unknown Sender"
	else:
		# Strip common variation suffixes
		var base_name = raw_character_name
		var variations = ["_child", "_Child", "_crying", "_ghost", "_ghostly", "_bad_ghost", "_good_ghost", "_ghost_1", "_ghost_2"]

		for v in variations:
			base_name = base_name.replace(v, "")

		# Remove leftover underscores and format nicely
		var parts = base_name.split("_")
		display_name = ""
		for part in parts:
			if part != "":
				display_name += part.capitalize() + " "
		display_name = display_name.strip_edges()


	character_label.visible = not raw_character_name.is_empty()
	character_label.text = tr(display_name, "dialogue")

	# === AUTO PORTRAIT HANDLER ===
	# === USE GLOBAL CHARACTER PORTRAITS ===
	var portrait_key = raw_character_name

	# Attempt fallback if exact name not found
	if not CharacterPortrait.portraits.has(portrait_key):
		portrait_key = portrait_key.capitalize()
	if not CharacterPortrait.portraits.has(portrait_key):
		portrait_key = portrait_key.to_lower()
	if not CharacterPortrait.portraits.has(portrait_key):
		portrait_key = portrait_key.replace("_", "")
	if not CharacterPortrait.portraits.has(portrait_key):
		portrait_key = portrait_key.capitalize().replace("_", "")

	# Apply portrait if found
	if CharacterPortrait.portraits.has(portrait_key):
		portrait.texture = CharacterPortrait.portraits[portrait_key]
	else:
		portrait.texture = null

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	balloon.show()
	will_hide_balloon = false

	# === Apply unknown sender visual flicker ===
	if raw_character_name.to_lower() == "unknown_sender":
		start_flicker()
		character_label.add_theme_color_override("default_color", Color.WHITE)
		dialogue_label.add_theme_color_override("default_color", Color.WHITE)
	else:
		stop_flicker()
		character_label.add_theme_color_override("default_color", Color(0, 0, 0))
		dialogue_label.add_theme_color_override("default_color", Color(0, 0, 0))


	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()
		next_indicators.show()
		update_next_label_text()



## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	mutation_cooldown.start(0.1)

# Left-click or 'dialog_next' key both advance dialogue (no skip typing)
func _on_balloon_gui_input(event: InputEvent) -> void:
	# Ignore if dialogue isn't waiting for input or has responses
	if not is_waiting_for_input or dialogue_line.responses.size() > 0:
		return

	get_viewport().set_input_as_handled()

	# === Left-click or 'next_action' advances dialogue ===
	var mouse_was_clicked : bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
	var next_button_pressed : bool = event.is_action_pressed(next_action)

	if mouse_was_clicked or next_button_pressed:
		next(dialogue_line.next_id)


#func _on_balloon_gui_input(event: InputEvent) -> void:
	## See if we need to skip typing of the dialogue
	#if dialogue_label.is_typing:
		#var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		#var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		#if mouse_was_clicked or skip_button_was_pressed:
		##if skip_button_was_pressed:
			#get_viewport().set_input_as_handled()
			#dialogue_label.skip_typing()
			#return
#
	#if not is_waiting_for_input: return
	#if dialogue_line.responses.size() > 0: return
#
	## When there are no response options the balloon itself is the clickable thing
	#get_viewport().set_input_as_handled()
#
	#if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		#next(dialogue_line.next_id)
	#elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		#next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


#endregion


func _on_dialogue_label_spoke(letter: String, letter_index: int, speed: float) -> void:
	if not letter in ["."," "]:
		talk_sound.pitch_scale = randf_range(0.9, 1.1)
		talk_sound.play()


func start_flicker():
	stop_flicker()
	
	# Instantly set the background to the dark tone (no fade-in)
	background_chat.self_modulate = Color(0.05, 0.0, 0.0, 1.0)
	
	flicker_tween = create_tween()
	flicker_tween.set_loops(-1)
	
	var color1 = Color(0.104, 0.0, 0.0, 1.0)
	var color2 = Color(0.05, 0.0, 0.0, 1.0)
	var color3 = Color(0.0, 0.0, 0.0, 1.0)
	
	flicker_tween.tween_property(background_chat, "self_modulate", color1, 0.6)
	flicker_tween.tween_property(background_chat, "self_modulate", color2, 0.6)
	flicker_tween.tween_property(background_chat, "self_modulate", color3, 0.8)
	flicker_tween.tween_property(background_chat, "self_modulate", color2, 0.6)
	flicker_tween.tween_property(background_chat, "self_modulate", color1, 0.6)



func stop_flicker():
	if flicker_tween and flicker_tween.is_valid():
		flicker_tween.stop()
	flicker_tween = null
	background_chat.self_modulate = Color(1, 1, 1, 1)


func update_next_label_text() -> void:
	var events = InputMap.action_get_events("dialog_next")
	if events.is_empty():
		next_label.text = ""
		return

	for event in events:
		if event is InputEventKey:
			next_label.text = " %s " % OS.get_keycode_string(event.physical_keycode)
			return

	next_label.text = ""
