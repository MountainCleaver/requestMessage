extends Control

const PATCH_API_URL := "https://requestmessage-admin.onrender.com/api/get_live_patch.php"

@onready var patch_holder = $patch_holder
@onready var version_label = $patch_holder/MarginContainer/ScrollContainer/VBoxContainer/version
@onready var date_label = $patch_holder/MarginContainer/ScrollContainer/VBoxContainer/date
@onready var notes_label = $patch_holder/MarginContainer/ScrollContainer/VBoxContainer/notes
@onready var http_request = $HTTP_request
@onready var loading_label = $menu_loading_screen/Label

func _ready():
	patch_holder.visible = false
	loading_label.visible = true
	
	http_request.connect("request_completed", Callable(self, "_on_patch_response"))
	fetch_live_patch()

func fetch_live_patch():
	var err = http_request.request(PATCH_API_URL)
	if err != OK:
		print("HTTP request error: ", err)

func _on_patch_response(result, response_code, headers, body):
	loading_label.visible = false

	if response_code != 200:
		print("Failed to fetch patch. Response code: ", response_code)
		version_label.text = "No live patch"
		date_label.text = "--/--/----"
		notes_label.text = "No notes available"
		patch_holder.visible = true
		return

	var json_text = body.get_string_from_utf8()
	var data = JSON.parse_string(json_text)
	if typeof(data) != TYPE_DICTIONARY or not data.has("version"):
		print("JSON parse error or missing data")
		version_label.text = "No live patch"
		date_label.text = "--/--/----"
		notes_label.text = "No notes available"
		patch_holder.visible = true
		return

	version_label.text = "Version " + str(data.version)
	var date_only = str(data.release_date).split(" ")[0]
	date_label.text = "Updated: " + date_only
	notes_label.text = data.patch_notes

	patch_holder.visible = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_on_back_pressed()
		
func _on_back_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")
