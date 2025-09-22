extends Control

@onready var icon: TextureRect = $Panel/MarginContainer/HBoxContainer/icon
@onready var app_name: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/app_name
@onready var notification_content: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/notification_content
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var icon_value : Texture;
@export var app_name_value : String;
@export var notif_value : String;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	icon.texture = icon_value;
	app_name.text = app_name_value;
	notification_content.text = notif_value;
	animation_player.play("notif_in");
