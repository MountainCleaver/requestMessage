extends Control

@onready var radio_fullscreen: CheckBox = $VBoxContainer/OPTIONS/FULLSCREEN/radio_fullscreen
@onready var radio_winowed: CheckBox = $VBoxContainer/OPTIONS/WINDOWED/radio_winowed
@onready var brightness_slider: HSlider = $VBoxContainer/SLIDER/brightness_slider

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var window_mode : String = Settings.window_mode;
	
	brightness_slider.value = Settings.brightness;
	
	if window_mode == "fullscreen":
		radio_fullscreen.button_pressed = true;
	elif window_mode == "windowed":
		radio_winowed.button_pressed = true;
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print("full screen: " + str(radio_fullscreen.button_pressed));
	print("windowed: "  + str(radio_winowed.button_pressed));
