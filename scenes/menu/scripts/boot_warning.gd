extends Control

@onready var splash_title: RichTextLabel = $splash_title
@onready var title_game: RichTextLabel = $title_game
@onready var warning_holder: Panel = $warning_holder
@onready var proceed: Panel = $proceed
@onready var button: Button = $proceed/Button
@onready var pck_loading_text: Label = $pck_loading_text
@onready var loading_sub_text: Label = $pck_loading_text/loading_sub_text

# --- VERSION CHECK NODES ---
@onready var version_label: Label = $menu_background/Version_Num_Major_Minor_Patch_pattern
@onready var outdated_layer: CanvasLayer = $outdated_version
@onready var outdated_loading: Label = $outdated_version/Label
@onready var outdated_update_label: Label = $outdated_version/UpdateLabel
@onready var outdated_update_now: Button = $outdated_version/UpdateNow

var logged_in: bool = false
var allow_input: bool = false
var fade_time := 1.0
var display_time := 2.0

var base_position_splash: Vector2
var motion_seed_splash: float
var time_acc: float = 0.0

var is_outdated: bool = false

# for extra pck loading
var pck_loaded : bool = false
var pck_loading : bool = false
var http_request: HTTPRequest

func _ready() -> void:
	outdated_layer.visible = false
	outdated_loading.visible = false
	outdated_update_label.visible = false
	outdated_update_now.visible = false

	pck_loading_text.hide()

	# Initial visibility
	splash_title.modulate.a = 0
	title_game.modulate.a = 0
	warning_holder.modulate.a = 0
	proceed.modulate.a = 0

	base_position_splash = splash_title.position
	motion_seed_splash = randf() * 10.0

	var user_data: Dictionary = Session.get_user_info()
	logged_in = not user_data.is_empty()
	button.pressed.connect(_on_proceed_pressed)

	#_fade_in_splash()
	#_check_version()

	if OS.has_feature("web"):
		print("Web platform detected")
		await get_tree().process_frame
		_load_pck_for_web()
	else:
		print("Desktop platform detected")
		pck_loaded = true
		_fade_in_splash()
		_check_version()


func _process(delta: float) -> void:
	time_acc += delta

	if splash_title.modulate.a > 0:
		var angle = time_acc * 2.0 + motion_seed_splash
		var radius_x = 4 + sin(time_acc * 1.0 + motion_seed_splash) * 4
		var radius_y = 3 + cos(time_acc * 1.3 + motion_seed_splash * 1.5) * 3
		splash_title.position = base_position_splash + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)



# ----------------------------------------------------------
#   VERSION CHECKING SYSTEM
# ----------------------------------------------------------

func _check_version() -> void:
	await get_tree().create_timer(0.5).timeout 

	var http := HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(_on_version_request_completed)

	var url := "https://requestmessage-admin.onrender.com/api/get_live_patch.php"
	http.request(url)


func _on_version_request_completed(_res, code, _headers, body):
	if code != 200:
		print("Version check failed, skipping.")
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		print("Invalid version JSON")
		return

	var live_version: String = str(json["version"])
	var local_version: String = version_label.text
	local_version = local_version.replace("Version ", "").strip_edges()

	# Compare
	if _is_version_outdated(local_version, live_version):
		is_outdated = true

		if not OS.has_feature("web"):
			_show_outdated_popup()
		else:
			print("Web detected: skip outdated popup")



func _is_version_outdated(local: String, live: String) -> bool:
	var a = local.split(".") 
	var b = live.split(".") 

	print("[Compare] Local Split:", a)
	print("[Compare] Live Split:", b)

	for i in 2:
		if int(a[i]) < int(b[i]):
			print("[Compare] -> local < live → OUTDATED")
			return true
		if int(a[i]) > int(b[i]):
			print("[Compare] -> local > live → NEWER or SAME")
			return false

	print("[Compare] Versions identical in major.minor → not outdated")
	return false




# ----------------------------------------------------------
#   OUTDATED VERSION UI
# ----------------------------------------------------------

func _show_outdated_popup() -> void:
	outdated_layer.visible = true

	outdated_loading.visible = true
	outdated_update_label.visible = false
	outdated_update_now.visible = false

	await get_tree().create_timer(5.0).timeout

	outdated_loading.visible = false
	outdated_update_label.visible = true
	outdated_update_now.visible = true

func _on_update_now_pressed() -> void:
	OS.shell_open("https://request-message.itch.io/request-message")


func _fade_in_splash() -> void:
	splash_title.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(splash_title, "modulate:a", 1, fade_time)
	tween.tween_callback(_on_fade_in_complete)

func _on_fade_in_complete() -> void:
	await get_tree().create_timer(display_time).timeout
	_fade_out_splash()

func _fade_out_splash() -> void:
	var tween = create_tween()
	tween.tween_property(splash_title, "modulate:a", 0, fade_time)
	tween.tween_callback(_show_main_warning)

func _show_main_warning() -> void:
	var tween = create_tween()
	tween.tween_property(title_game, "modulate:a", 1, fade_time)
	tween.tween_property(warning_holder, "modulate:a", 1, fade_time)
	tween.tween_property(proceed, "modulate:a", 1, fade_time)

	allow_input = true


func _input(event: InputEvent) -> void:
	if not allow_input:
		return

	if event.is_action_pressed("accept"):
		_on_proceed_pressed()


func _on_proceed_pressed() -> void:
	if is_outdated:
		print("Game outdated. Block going to menu.")
		return

	if OS.has_feature("web") and pck_loading:
		print("You cannot yet, is still loading pck...")
		return
	_go_next_scene()


func _go_next_scene() -> void:
	if not logged_in:
		SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn")
	else:
		SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")


func _load_pck_for_web () -> void:
	pck_loading = true
	pck_loading_text.show()
	
	http_request = HTTPRequest.new()
	add_child(http_request)
	await get_tree().process_frame
	http_request.request_completed.connect(_on_pck_downloaded)
	
	http_request.accept_gzip = false
	http_request.body_size_limit = -1
	http_request.use_threads = false
	http_request.timeout = 600.0
	
	var base_url = JavaScriptBridge.eval("window.location.href")
	
	if base_url.contains("index.html"):
		base_url = base_url.replace("index.html", "")
		
	if not base_url.ends_with("/"):
		base_url += "/"
	
	var pck_url = base_url + "other_audio.pck"
	print("downloading extra pck from : " + pck_url)
	
	var error = http_request.request(pck_url)
	if error != OK:
		print("Failed to initiate pck request.")
		print("error code: " + error)
		pck_loading = false
		#pck_loading_text.hide()
		#_fade_in_splash()
		$pck_loading_text/AnimationPlayer.stop()
		pck_loading_text.text = ""
		loading_sub_text.text = "Loading failed, please restart your browser."
		return

func _on_pck_downloaded (result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	pck_loading = false
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or body.size() == 0:
		print("Failed to dowload PCK")
		#pck_loading_text.hide()
		#_fade_in_splash()
		$pck_loading_text/AnimationPlayer.stop()
		pck_loading_text.text = ""
		loading_sub_text.text = "Loading failed, please restart your browser."
		return
	
	var path = "user://other_audio.pck"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_buffer(body)
		file.close()
		print("other_audio.pck is save to : " + path)
	
	var ok = ProjectSettings.load_resource_pack(path)
	pck_loaded = ok
	if ok:
		print("PCK loading SUCCESSFUL")
		pck_loading_text.hide()
		_fade_in_splash()
	else:
		print("PCK loading FAILED")
		$pck_loading_text/AnimationPlayer.stop()
		pck_loading_text.text = ""
		loading_sub_text.text = "Loading failed, please restart your browser."
	if http_request:
		http_request.queue_free()
	
	
	
