extends Control

@onready var icon: TextureRect = $Panel/MarginContainer/HBoxContainer/icon
@onready var app_name: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/app_name
@onready var notification_content: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/notification_content
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var notif_sound: AudioStreamPlayer = $NotifSound  

@export var icon_value : Texture
@export var app_name_value : String
@export var notif_value : String
@export var notif_audio: AudioStream 

func _ready() -> void:
	icon.texture = icon_value
	app_name.text = app_name_value
	notification_content.text = notif_value
	
	# play sound if assigned
	if notif_audio:
		notif_sound.stream = notif_audio
		notif_sound.play()
	
	# play the animation
	animation_player.play("notif_in")
