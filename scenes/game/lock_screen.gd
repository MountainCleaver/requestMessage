extends Control

@onready var time: Label = $Panel/time
@onready var lock: Button = $Panel/lock
@onready var notifications_container: VBoxContainer = $Panel/Panel/ScrollContainer/notifications_container
const NOTIFICATION = preload("res://scenes/game/notification.tscn")

@export var time_value: String
@export var lock_visible: bool = false
@export var phone_scenes: Array[PackedScene] = []      # [0]=Danilo, [1]=Wendy

var objectives_done: bool = false 

func _ready() -> void:
	lock.visible = lock_visible
	time.text = time_value
	
	lock.pressed.connect(_on_lock_pressed)


func _on_lock_pressed() -> void:
	if objectives_done:
		queue_free()
		return

	var current_scene_name = get_tree().current_scene.name.to_lower()
	var pov = 0

	# Detect ONLY Act 2 Scene 4 (Wendy’s POV) HAAAAAA
	if current_scene_name == "act_2_scene_4":
		pov = 1

	print("Scene:", current_scene_name, "→ POV index:", pov)

	if pov >= 0 and pov < phone_scenes.size() and phone_scenes[pov]:
		var phone_menu := phone_scenes[pov].instantiate()
		get_parent().add_child(phone_menu)

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

		queue_free()
	else:
		push_error("❌ No valid phone scene found for POV index " + str(pov))

func add_notification(texture: Texture, app_name: String, content: String ) -> void :
	var notif_instance = NOTIFICATION.instantiate();
	notif_instance.icon_value = texture;
	notif_instance.app_name_value = app_name;
	notif_instance.notif_value = content;
	
	notifications_container.add_child(notif_instance);
	notifications_container.move_child(notif_instance, 0);

