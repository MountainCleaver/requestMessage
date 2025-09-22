extends Control

@onready var time: Label = $Panel/time
@onready var lock: Button = $Panel/lock

@onready var notifications_container: VBoxContainer = $Panel/Panel/ScrollContainer/notifications_container

const NOTIFICATION = preload("res://scenes/game/notification.tscn")
@export var lock_visible :bool = false;

func _ready() -> void:
	lock.visible = lock_visible;
	print(notifications_container)
	

func _on_lock_pressed() -> void:
	var parent = get_parent();
	var phone_menu = preload("res://scenes/game/phone_main.tscn").instantiate();
	parent.add_child(phone_menu)


func add_notification(texture: Texture, app_name: String, content: String ) -> void :
	var notif_instance = NOTIFICATION.instantiate();
	notif_instance.icon_value = texture;
	notif_instance.app_name_value = app_name;
	notif_instance.notif_value = content;
	
	$Panel/Panel/ScrollContainer/notifications_container.add_child(notif_instance);
