extends Control

@onready var time: Label = $Panel/time
@onready var lock: Button = $Panel/lock
@onready var notifications_container: VBoxContainer = $Panel/Panel/ScrollContainer/notifications_container

const NOTIFICATION = preload("res://scenes/game/notification.tscn")

@export var time_value: String
@export var lock_visible: bool = false
@export var phone_scenes: Array[PackedScene] = []  # [0]=Danilo, [1]=Wendy

var objectives_done: bool = false

func _ready() -> void:
	lock.visible = lock_visible
	time.text = time_value
	lock.pressed.connect(_on_lock_pressed)
	print("Notifications container:", notifications_container)


func _on_lock_pressed() -> void:
	if objectives_done:
		queue_free()
		return

	var pov := _get_pov_index()
	print("Scene:", get_tree().current_scene.name, "→ POV index:", pov)

	if pov < 0 or pov >= phone_scenes.size() or not phone_scenes[pov]:
		push_error("❌ No valid phone scene found for POV index " + str(pov))
		return

	var phone_menu = phone_scenes[pov].instantiate()
	get_parent().add_child(phone_menu)

	var current_scene = get_tree().current_scene
	var current_scene_name = current_scene.name.to_lower()

	if current_scene_name == "act_1_scene_4" and phone_menu.has_signal("phone_locked"):
		phone_menu.phone_locked.connect(
			Callable(current_scene, "_on_phone_locked")
		)
		print("Connected phone_locked signal for Danilo's phone")

	if pov == 1:
		print("Opened phone for: Wendy")
	else:
		print("Opened phone for: Danilo")

	if "all_chats_checked" in current_scene:
		print("Connecting lock_pressed_for_last_objective signal...")
		phone_menu.connect(
			"lock_pressed_for_last_objective",
			Callable(current_scene, "_on_last_objective_lock_pressed")
		)

	visible = true

func add_notification(texture: Texture, app_name: String, content: String) -> void:
	var notif_instance = NOTIFICATION.instantiate()
	notif_instance.icon_value = texture
	notif_instance.app_name_value = app_name
	notif_instance.notif_value = content
	notifications_container.add_child(notif_instance)
	notifications_container.move_child(notif_instance, 0)

func clear_notifications() -> void:
	for notif in notifications_container.get_children():
		notif.queue_free()
	await get_tree().process_frame

func _get_pov_index() -> int:
	var current_scene_name = get_tree().current_scene.name.to_lower()
	match current_scene_name:
		"act_2_scene_4":
			return 1  # Wendy
		_:
			return 0  # Danilo (default)
