extends Control

@onready var completion_panel = $"HBoxContainer/completion_button"
@onready var achievements_panel = $"HBoxContainer/achievements_button"
@onready var completion_vbox = $"HBoxContainer/completion_button/completion_holder/MarginContainer/ScrollContainer/VBoxContainer"
@onready var achievements_vbox = $"HBoxContainer/achievements_button/achievements_holder/MarginContainer/ScrollContainer/VBoxContainer"
@onready var loading_label = $menu_loading_screen/Label
@onready var h_separator = $HSeparator
@onready var hbox_completion = $HBoxContainer/completion_button/HBoxContainer
@onready var hbox_achievements = $HBoxContainer/achievements_button/HBoxContainer
@onready var back_button: Button = $back_tips/back

@onready var http_completion := HTTPRequest.new()
@onready var http_achievements := HTTPRequest.new()

var completion_leaderboard_data: Array = []
var achievements_leaderboard_data: Array = []


func _ready():
	show_completion_panel()
	add_child(http_completion)
	add_child(http_achievements)

	http_completion.connect("request_completed", Callable(self, "_on_leaderboard_fetched"))
	http_achievements.connect("request_completed", Callable(self, "_on_achievements_leaderboard_fetched"))
	h_separator.visible = false
	hbox_completion.visible = false
	hbox_achievements.visible = false
	fetch_completion_leaderboard()
	fetch_achievements_leaderboard()


func fetch_completion_leaderboard():
	loading_label.visible = true 
	h_separator.visible = false
	hbox_completion.visible = false
	hbox_achievements.visible = false
	var url = "https://requestmessage-admin.onrender.com/api/get_leaderboard.php?type=completion"
	http_completion.request(url)


func fetch_achievements_leaderboard():
	loading_label.visible = true 
	h_separator.visible = false
	hbox_completion.visible = false
	hbox_achievements.visible = false

	var url = "https://requestmessage-admin.onrender.com/api/get_leaderboard.php?type=achievements"
	http_achievements.request(url)


func _on_completion_button_pressed():
	show_completion_panel()


func _on_achievements_button_pressed():
	show_achievements_panel()


func show_completion_panel():
	# completion on
	completion_panel.get_node("HBoxContainer").visible = true
	completion_panel.get_node("completion_holder").visible = true
	
	# achievements off
	achievements_panel.get_node("HBoxContainer").visible = false
	achievements_panel.get_node("achievements_holder").visible = false
	
	show_current_user_rank(completion_leaderboard_data, $HSeparator/current_rank, $HSeparator/no_data_label, "completion")


func show_achievements_panel():
	# completion off
	completion_panel.get_node("HBoxContainer").visible = false
	completion_panel.get_node("completion_holder").visible = false

	# achievements on
	achievements_panel.get_node("HBoxContainer").visible = true
	achievements_panel.get_node("achievements_holder").visible = true
	
	show_current_user_rank(achievements_leaderboard_data, $HSeparator/current_rank, $HSeparator/no_data_label, "achievements")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_on_back_pressed()


func _on_back_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_main.tscn")


func _on_leaderboard_fetched(result, response_code, headers, body):
	loading_label.visible = false 
	h_separator.visible = true 
	hbox_completion.visible = true
	if response_code != 200:
		print("Failed to fetch leaderboard:", response_code)
		return

	var body_text = body.get_string_from_utf8()
	var leaderboard_data = JSON.parse_string(body_text)

	if typeof(leaderboard_data) != TYPE_ARRAY:
		print("Leaderboard JSON is not an Array. Got:", typeof(leaderboard_data))
		return

	# Clear existing rows
	for child in completion_vbox.get_children():
		child.queue_free()

	# Display only top 10
	var max_display = 10
	for i in range(min(max_display, leaderboard_data.size())):
		var player = leaderboard_data[i]

		var row_hbox = HBoxContainer.new()
		row_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row_hbox.custom_minimum_size = Vector2(0, 55)

		var label_settings = LabelSettings.new()
		label_settings.font = load("res://assets/fonts/basis33.ttf")
		label_settings.font_size = 28
		label_settings.line_spacing = 3.0

		# Rank
		var rank_label = Label.new()
		rank_label.text = str(int(player.get("rank", 0)))
		rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rank_label.vertical_alignment = 1
		rank_label.horizontal_alignment = 1
		rank_label.size_flags_stretch_ratio = 0.35
		rank_label.label_settings = label_settings.duplicate(true)
		row_hbox.add_child(rank_label)

		# Username
		var username_label = Label.new()
		username_label.text = player.get("username", "-")
		username_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		username_label.vertical_alignment = 1
		username_label.horizontal_alignment = 1
		username_label.size_flags_stretch_ratio = 1.56
		username_label.label_settings = label_settings.duplicate(true)
		row_hbox.add_child(username_label)

		# Time Completed (H:M:S)
		var time_label = Label.new()
		var total_seconds = int(player.get("playtime_seconds", 0))
		var hours = total_seconds / 3600
		var minutes = (total_seconds % 3600) / 60
		var secs = total_seconds % 60
		time_label.text = "%d:%02d:%02d" % [hours, minutes, secs]
		time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		time_label.vertical_alignment = 1
		time_label.horizontal_alignment = 1
		time_label.size_flags_stretch_ratio = 1.0
		time_label.label_settings = label_settings.duplicate(true)
		row_hbox.add_child(time_label)

		# Date Completed (YYYY-MM-DD)
		var date_label = Label.new()
		var full_date = player.get("achieved_at", "-")
		if full_date != "-":
			date_label.text = full_date.split(" ")[0]
		else:
			date_label.text = "-"
		date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		date_label.vertical_alignment = 1
		date_label.horizontal_alignment = 1
		date_label.size_flags_stretch_ratio = 1.0
		date_label.label_settings = label_settings.duplicate(true)
		row_hbox.add_child(date_label)

		completion_vbox.add_child(row_hbox)
		completion_leaderboard_data = leaderboard_data
		
		if completion_panel.get_node("HBoxContainer").visible:
			show_current_user_rank(completion_leaderboard_data, $HSeparator/current_rank, $HSeparator/no_data_label, "completion")

func _on_achievements_leaderboard_fetched(result, response_code, headers, body):
	loading_label.visible = false 
	h_separator.visible = true 

	if response_code != 200:
		print("Failed to fetch achievements leaderboard:", response_code)
		return

	var body_text = body.get_string_from_utf8()
	var leaderboard_data = JSON.parse_string(body_text)

	if typeof(leaderboard_data) != TYPE_ARRAY:
		print("Achievements JSON is not an Array. Got:", typeof(leaderboard_data))
		return

	# Clear existing rows
	var achievements_vbox = achievements_panel.get_node("achievements_holder/MarginContainer/ScrollContainer/VBoxContainer")
	for child in achievements_vbox.get_children():
		child.queue_free()

	# Display top 10
	var max_display = 10
	for i in range(min(max_display, leaderboard_data.size())):
		var player = leaderboard_data[i]

		var row_hbox = HBoxContainer.new()
		row_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row_hbox.custom_minimum_size = Vector2(0, 55)

		var label_settings = LabelSettings.new()
		label_settings.font = load("res://assets/fonts/basis33.ttf")
		label_settings.font_size = 28
		label_settings.line_spacing = 3.0

		# Rank
		var rank_label = Label.new()
		rank_label.text = str(int(player.get("rank", 0)))
		rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rank_label.vertical_alignment = 1
		rank_label.horizontal_alignment = 1
		rank_label.size_flags_stretch_ratio = 0.35
		rank_label.label_settings = label_settings.duplicate(true)
		row_hbox.add_child(rank_label)

		# Username
		var username_label = Label.new()
		username_label.text = player.get("username", "-")
		username_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		username_label.vertical_alignment = 1
		username_label.horizontal_alignment = 1
		username_label.size_flags_stretch_ratio = 1.56
		username_label.label_settings = label_settings.duplicate(true)
		row_hbox.add_child(username_label)

		# Total Achievements
		var total_label = Label.new()
		total_label.text = str(player.get("total_achievements", 0))
		total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		total_label.vertical_alignment = 1
		total_label.horizontal_alignment = 1
		total_label.size_flags_stretch_ratio = 1.0
		total_label.label_settings = label_settings.duplicate(true)
		row_hbox.add_child(total_label)

		# Last Achieved At
		var date_label = Label.new()
		var full_datetime = player.get("earliest_unlocked", "-")  # Use correct JSON key
		date_label.text = full_datetime if full_datetime != "-" else "-"
		date_label.text = full_datetime.replace(" ", "\n")
		date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		date_label.vertical_alignment = 1
		date_label.horizontal_alignment = 1
		date_label.size_flags_stretch_ratio = 1.0
		date_label.label_settings = label_settings.duplicate(true)
		row_hbox.add_child(date_label)

		achievements_vbox.add_child(row_hbox)
		achievements_leaderboard_data = leaderboard_data 


func show_current_user_rank(leaderboard_data: Array, current_rank_box: Control, no_data_label: Label, type: String = "completion") -> void:
	var current_user_id = SaveManager.current_user_id
	
	# Dev exclusion for testing
	if current_user_id in [1, 2, 3, 4, 5]:
		current_rank_box.visible = false
		no_data_label.visible = true
		no_data_label.text = "Nice try, dev. No leaderboard glory for you."
		return
	
	var found_user = false
	
	for player in leaderboard_data:
		if str(player.get("user_id", "")) == str(current_user_id):
			found_user = true
			current_rank_box.visible = true
			no_data_label.visible = false
			
			# Completion leaderboard
			if type == "completion":
				current_rank_box.get_node("rank/Label").text = str(int(player.get("rank", 0)))
				current_rank_box.get_node("username/Label").text = str(player.get("username", "-"))
				
				var seconds = int(player.get("playtime_seconds", 0))
				var h = seconds / 3600
				var m = (seconds % 3600) / 60
				var s = seconds % 60
				current_rank_box.get_node("time_completed/Label").text = "%d:%02d:%02d" % [h, m, s]
				
				var date_full = player.get("achieved_at", "-")
				current_rank_box.get_node("date_completed/Label").text = date_full.split(" ")[0]
			
			# Achievements leaderboard
			elif type == "achievements":
				current_rank_box.get_node("rank/Label").text = str(int(player.get("rank", 0)))
				current_rank_box.get_node("username/Label").text = str(player.get("username", "-"))
				current_rank_box.get_node("time_completed/Label").text = str(player.get("total_achievements", 0))
				var earliest = player.get("earliest_unlocked", "-")
				current_rank_box.get_node("date_completed/Label").text = earliest.split(" ")[0] if earliest != "-" else "-"
			
			break
	
	if not found_user:
		current_rank_box.visible = false
		no_data_label.visible = true
		if type == "completion":
			no_data_label.text = "No completion data. Finish the game to view your placement."
		elif type == "achievements":
			no_data_label.text = "No achievements data. Unlock some badges to view your placement."


func send_request(url: String, json_body: String):
	loading_label.visible = true
	var request = HTTPRequest.new()
	add_child(request)

	request.connect("request_completed", Callable(self, "_on_request_done"))
	request.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		json_body
	)


func _on_request_done(result, response_code, headers, body):
	loading_label.visible = false
	print("REQUEST DONE, CODE:", response_code)
