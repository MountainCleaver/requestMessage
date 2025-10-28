extends Control

@onready var radio_english: CheckBox = $VBoxContainer/OPTIONS/ENGLISH/radio_english
@onready var radio_filipino: CheckBox = $VBoxContainer/OPTIONS/FILIPINO/radio_filipino

func _ready() -> void:
	# Set initial selection
	var current_lang: String = Settings.settings.dialogue_language
	radio_english.button_pressed = current_lang == "en"
	radio_filipino.button_pressed = current_lang != "en"

	# Connect signals
	radio_english.toggled.connect(_on_radio_english_toggled)
	radio_filipino.toggled.connect(_on_radio_filipino_toggled)

func _on_radio_english_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Settings.settings.dialogue_language = "en"
		Settings.save_settings()
		radio_filipino.button_pressed = false
		_update_current_scene_language()

func _on_radio_filipino_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Settings.settings.dialogue_language = "fil"
		Settings.save_settings()
		radio_english.button_pressed = false
		_update_current_scene_language()

func _update_current_scene_language() -> void:
	if get_tree().current_scene and get_tree().current_scene.has_method("_load_dialogue"):
		get_tree().current_scene._load_dialogue()
