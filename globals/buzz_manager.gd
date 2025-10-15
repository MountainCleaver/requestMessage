# PARA SA PHONE PARA DI NA PALAGI TAWAGIN FUNCTION KADA SCENE
extends Node

var buzz_audio: AudioStreamPlayer
var buzz_timer: Timer
var buzz_delay := 1.5  

func _ready():
	buzz_audio = AudioStreamPlayer.new()
	add_child(buzz_audio)
	buzz_audio.stream = preload("res://sound/mobile-vibrate-sfx-323777.mp3")

	buzz_timer = Timer.new()
	add_child(buzz_timer)
	buzz_timer.wait_time = buzz_delay
	buzz_timer.connect("timeout", Callable(self, "_on_buzz_timeout"))

# ===================
# BUZZ FUNCTIONS
# ===================
func start_buzz():
	if buzz_audio:
		buzz_audio.play()
		buzz_timer.start()

func stop_buzz():
	if buzz_audio:
		buzz_audio.stop()
		buzz_timer.stop()

func _on_buzz_timeout():
	if buzz_audio:
		buzz_audio.play()
		buzz_timer.start() 
