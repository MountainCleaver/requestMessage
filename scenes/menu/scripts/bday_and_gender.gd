extends Control

@onready var month_line: LineEdit = $Panel/MarginContainer/vbox_all/vbox_date/HBoxContainer/month_line
@onready var day_line: LineEdit = $Panel/MarginContainer/vbox_all/vbox_date/HBoxContainer/day_line
@onready var year_line: LineEdit = $Panel/MarginContainer/vbox_all/vbox_date/HBoxContainer/year_line

@onready var male: Button = $Panel/MarginContainer/vbox_all/vbox_gender/genders_container/male
@onready var female: Button = $Panel/MarginContainer/vbox_all/vbox_gender/genders_container/female
@onready var metal: Button = $Panel/MarginContainer/vbox_all/vbox_gender/genders_container/metal

@onready var btn_accept: Button = $Panel/MarginContainer/vbox_all/vbox_enter/HBoxContainer/btn_accept

@onready var button: Button = $Button

@onready var error_label: Label = $Panel/MarginContainer/vbox_all/error_label  

const BASIS_33 = preload("res://assets/fonts/basis33.ttf")

var genders = ["Male", "Female", "Ambigious"]
var selected_gender : String = ""

@onready var genders_container: HBoxContainer = $Panel/MarginContainer/vbox_all/vbox_gender/genders_container

@onready var confirmation_dialog: Control = $"../AgeConfirmation"
@onready var window: Window = $"../AgeConfirmation/Window"

func _ready() -> void:
	month_line.text_changed.connect(_on_month_text_changed)
	day_line.text_changed.connect(_on_day_text_changed)
	year_line.text_changed.connect(_on_year_text_changed)
	error_label.text = ""
	error_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	error_label.add_theme_font_size_override("font_size", 24)

func _process(delta: float) -> void:
	btn_accept.disabled = (selected_gender == "")

func _on_month_text_changed(new_text: String) -> void:
	if new_text == "":
		return
	var m = int(new_text)
	if m < 1 or m > 12:
		month_line.text = ""

func _on_day_text_changed(new_text: String) -> void:
	if new_text == "":
		return
	var d = int(new_text)
	if d < 1 or d > 31:
		day_line.text = ""

func _on_year_text_changed(new_text: String) -> void:
	var regex := RegEx.new()
	regex.compile("\\D")
	var cleaned := regex.sub(new_text, "", true)
	if cleaned != new_text:
		year_line.text = cleaned

func _is_leap_year(year: int) -> bool:
	return year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)

func _on_btn_accept_pressed() -> void:
	error_label.text = ""  

	if month_line.text == "" or day_line.text == "" or year_line.text == "":
		error_label.text = "Birthday fields incomplete."
		return

	var month_val: int = int(month_line.text)
	var day_val: int = int(day_line.text)
	var year_val: int = int(year_line.text)

	# YEAR RANGE VALIDATION
	if year_val < 1950 or year_val > 2025:
		error_label.text = "Year must be between 1950 and 2007."
		return

	# MONTH RANGE VALIDATION
	if month_val < 1 or month_val > 12:
		error_label.text = "Month must be between 1 and 12."
		return

	# DAY RANGE VALIDATION (with leap year logic)
	var month_days: Dictionary = {
		1: 31, 2: 28, 3: 31, 4: 30, 5: 31, 6: 30,
		7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31
	}
	var max_days: int = month_days.get(month_val, 31)
	if month_val == 2 and _is_leap_year(year_val):
		max_days = 29
	if day_val < 1 or day_val > max_days:
		error_label.text = "Invalid day for that month and year."
		return

	var now = Time.get_datetime_dict_from_system()
	var current_month: int = now.month
	var current_day: int = now.day
	var current_year: int = now.year

	var age: int = current_year - year_val
	if current_month < month_val or (current_day < day_val and current_month == month_val):
		age -= 1

	if age < 18:
		print("is minor")
		confirmation_dialog.show()
		window.show()
	else:
		print("is adult")

		var birthday = str(year_val) + "-" + str(month_val).pad_zeros(2) + "-" + str(day_val).pad_zeros(2)
		var gender = selected_gender

		get_tree().set_meta("birthday", birthday)
		get_tree().set_meta("gender", gender)

		SignalBus.next_scene.emit("res://scenes/menu/menu_create_acc_creds.tscn")

	print("Final age: " + str(age))
	print("BirthDate: " + str(month_val) + " " + str(day_val) + " " + str(year_val))
	print("Gender: " + selected_gender)

func _on_male_pressed() -> void:
	selected_gender = genders[0]

func _on_female_pressed() -> void:
	selected_gender = genders[1]

func _on_metal_pressed() -> void:
	selected_gender = genders[2]

func _on_button_pressed() -> void:
	SignalBus.next_scene.emit("res://scenes/menu/menu_login_acc.tscn")
