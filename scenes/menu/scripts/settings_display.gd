extends Control

@onready var radio_fullscreen: CheckBox = $VBoxContainer/OPTIONS/FULLSCREEN/radio_fullscreen
@onready var radio_winowed: CheckBox = $VBoxContainer/OPTIONS/WINDOWED/radio_winowed
@onready var brightness_slider: HSlider = $VBoxContainer/SLIDER/brightness_slider

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var window_mode : String = Settings.settings.window_mode;
	
	brightness_slider.value = Settings.settings.brightness;
	
	if window_mode == "fullscreen":
		radio_fullscreen.button_pressed = true;
	elif window_mode == "windowed":
		radio_winowed.button_pressed = true;
		
	radio_fullscreen.toggled.connect(_on_radio_fullscreen_toggled);
	radio_winowed.toggled.connect(_on_radio_windowed_toggled);
	brightness_slider.value_changed.connect(_on_brightness_slider_value_changed);

func _on_radio_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		Settings.settings.window_mode = "fullscreen"
		Settings.save_settings();

func _on_radio_windowed_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		Settings.settings.window_mode = "windowed"
		Settings.save_settings();

func _on_brightness_slider_value_changed(value: float) -> void:
	BrightnessManager.set_brightness(value)
	
	# Save to settings
	Settings.settings.brightness = value
	Settings.save_settings()
	
	# Emit signal to let other scenes know
	SignalBus.brightness_changed.emit(value)
