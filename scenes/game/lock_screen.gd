extends Control

@onready var time: Label = $Panel/time
@onready var lock: Button = $Panel/lock

@export var time_value : String;

@onready var notifications_container: VBoxContainer = $Panel/Panel/ScrollContainer/notifications_container

const NOTIFICATION = preload("res://scenes/game/notification.tscn")
@export var lock_visible :bool = false;

func _ready() -> void:
<<<<<<< Updated upstream
	lock.visible = lock_visible;
	print(notifications_container)
	time.text = time_value;
	
=======
	lock.visible = lock_visible
	print(notifications_container)
	time.text = time_value
	
	# Connect the lock button signal
	lock.pressed.connect(_on_lock_pressed)
>>>>>>> Stashed changes

func _on_lock_pressed() -> void:
	var parent = get_parent()
	var phone_menu = preload("res://scenes/game/phone_main.tscn").instantiate()
	parent.add_child(phone_menu)

	if "all_chats_checked" in get_tree().current_scene:
		phone_menu.connect("lock_pressed_for_last_objective", Callable(get_tree().current_scene, "_on_last_objective_lock_pressed"))

<<<<<<< Updated upstream

func add_notification(texture: Texture, app_name: String, content: String ) -> void :
	var notif_instance = NOTIFICATION.instantiate();
	notif_instance.icon_value = texture;
	notif_instance.app_name_value = app_name;
	notif_instance.notif_value = content;
	
	notifications_container.add_child(notif_instance);
	notifications_container.move_child(notif_instance, 0);
=======
	if current_scene_name == "act_2_scene_4":
		pov = 1

	print("Scene:", current_scene_name, "→ POV index:", pov)

	if pov >= 0 and pov < phone_scenes.size() and phone_scenes[pov]:
		var phone_menu = phone_scenes[pov].instantiate()
		get_parent().add_child(phone_menu)

		if current_scene_name == "act_1_scene_4" and phone_menu.has_signal("phone_locked"):
			phone_menu.phone_locked.connect(
				Callable(get_tree().current_scene, "_on_phone_locked")
			)
			print("Connected phone_locked signal for Danilo's phone")

		if pov == 1:
			print("Opened phone for: Wendy")
		else:
			print("Opened phone for: Danilo")

		if "all_chats_checked" in get_tree().current_scene:
			print("Connecting lock_pressed_for_last_objective signal...")
			phone_menu.connect(
				"lock_pressed_for_last_objective",
				Callable(get_tree().current_scene, "_on_last_objective_lock_pressed")
			)

		visible = true
	else:
		push_error("❌ No valid phone scene found for POV index " + str(pov))

func add_notification(texture: Texture, app_name: String, content: String) -> void:
	var notif_instance = NOTIFICATION.instantiate()
	notif_instance.icon_value = texture
	notif_instance.app_name_value = app_name
	notif_instance.notif_value = content
	notifications_container.add_child(notif_instance)
>>>>>>> Stashed changes
