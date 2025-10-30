extends Resource

class_name SettingsResource

#audio
@export var music_volume: float = 80.0
@export var sfx_volume: float = 80.0
@export var mute_all_sounds: bool = true

#display
@export var window_mode: String = "windowed"
@export var brightness: float = 90.0

#dialogue language
@export var dialogue_language: String = "fil" 

# user key bindings
@export var key_bindings: Dictionary = {}
