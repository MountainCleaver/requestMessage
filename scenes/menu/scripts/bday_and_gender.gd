extends Control

@onready var month: OptionButton = $Panel/MarginContainer/vbox_all/vbox_date/HBoxContainer/month
@onready var day: OptionButton = $Panel/MarginContainer/vbox_all/vbox_date/HBoxContainer/day
@onready var year: OptionButton = $Panel/MarginContainer/vbox_all/vbox_date/HBoxContainer/year

@onready var male: Button = $Panel/MarginContainer/vbox_all/vbox_gender/genders_container/male
@onready var female: Button = $Panel/MarginContainer/vbox_all/vbox_gender/genders_container/female
@onready var metal: Button = $Panel/MarginContainer/vbox_all/vbox_gender/genders_container/metal

@onready var btn_accept: Button = $Panel/MarginContainer/vbox_all/vbox_enter/HBoxContainer/btn_accept

@onready var month_popup: PopupMenu = month.get_popup();
@onready var day_popup: PopupMenu = day.get_popup();
@onready var year_popup: PopupMenu = year.get_popup();

const BASIS_33 = preload("res://assets/fonts/basis33.ttf");

var year_range = range(2025, 1949, -1);
var genders = ["male", "female", "ambigious"];
var selected_gender : String = "";

var month_days := {
	"JAN": 31,
	"FEB": 28, 
	"MAR": 31,
	"APR": 30,
	"MAY": 31,
	"JUN": 30,
	"JUL": 31,
	"AUG": 31,
	"SEP": 30,
	"OCT": 31,
	"NOV": 30,
	"DEC": 31
}

@onready var genders_container: HBoxContainer = $Panel/MarginContainer/vbox_all/vbox_gender/genders_container



func _ready() -> void:
	_assign_months();
	_assign_years();
	
	_style_popup(month_popup);
	_style_popup(day_popup);
	_style_popup(year_popup);
	
	_style_option_button(month);
	_style_option_button(year);
	_style_option_button(day);
	

func _process(delta: float) -> void:
	#print("Accept disabled:", btn_accept.disabled)
	if selected_gender == "":
		btn_accept.disabled = true;
	else:
		btn_accept.disabled = false;
		

func _assign_months() -> void:
	for m in month_days.keys():
		month.add_item(m);
		
	month.select(0);
	_on_month_item_selected(0);
	
func _assign_years() -> void:
	for y in year_range:
		year.add_item(str(y));
	
	year.select(0);
	_on_year_item_selected(0);

func _assign_days(max_days: int) -> void:
	day.clear();
	
	var days_range = range(1, max_days+1);
	
	for d in days_range:
		day.add_item(str(d));
	day.select(0);
	_on_day_item_selected(0);


func _is_leap_year(year:int) -> bool:
	return year % 400 == 0 or (year % 4 == 0 and year % 100 != 0);

func _on_month_item_selected(index: int) -> void:
	var selected_month = month_days.keys()[index];
	#print("month :" + selected_month);
	
	if selected_month == "FEB" and _is_leap_year(year_range[year.selected]):
		_assign_days(29);
	else:
		_assign_days(month_days.values()[index]);
	

func _on_day_item_selected(index: int) -> void:
	print("day: " + str(index+1));

func _on_year_item_selected(index: int) -> void:
	var selected_year = year_range[index]
	
	if _is_leap_year(selected_year):
		print("leap year");
		if month.selected == 1:
			_assign_days(29)
	else:
		print("not leap year")
	
	print("year: " + str(selected_year));


func _style_popup(popup: PopupMenu) -> void:
	print(popup.name)

	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = "#efefef"
	popup.add_theme_stylebox_override("panel", style)
	
	# Fonts
	popup.add_theme_font_override("font", BASIS_33)
	popup.add_theme_font_size_override("font_size", 28)
	popup.add_theme_color_override("font_color", "#181818")
	popup.add_theme_color_override("font_hover_color", Color.YELLOW)
	
	# Limit height
	popup.max_size = Vector2(200, 200) # 200px tall max, width auto

func _style_option_button(option_btn: OptionButton) -> void:
	
	# style
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = "#c2c3cb" 
	hover_style.expand_margin_bottom = 5
	hover_style.expand_margin_top = 5
	hover_style.expand_margin_right = 5
	hover_style.expand_margin_left = 5
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = "#efefef"
	normal_style.border_color = "#888c92"
	normal_style.expand_margin_bottom = 5
	normal_style.expand_margin_top = 5
	normal_style.expand_margin_right = 5
	normal_style.expand_margin_left = 5
	normal_style.border_width_top = 1
	normal_style.border_width_bottom = 1
	normal_style.border_width_right = 1
	normal_style.border_width_left = 1
	
	# Add any other styling like borders, corner radius, etc.
	if option_btn.name == "month":
		hover_style.corner_radius_top_left = 15;
		hover_style.corner_radius_bottom_left = 15;
		normal_style.corner_radius_top_left = 15;
		normal_style.corner_radius_bottom_left = 15;
		
	elif option_btn.name == "day":
		hover_style.corner_radius_top_left = 0;
		hover_style.corner_radius_bottom_left = 0;
		
	elif option_btn.name == "year":
		hover_style.corner_radius_top_right = 15;
		hover_style.corner_radius_bottom_right = 15;
		normal_style.corner_radius_top_right = 15;
		normal_style.corner_radius_bottom_right = 15;
	
	# Apply to different states
	option_btn.add_theme_stylebox_override("hover", hover_style)
	option_btn.add_theme_stylebox_override("pressed", hover_style)
	option_btn.add_theme_stylebox_override("focus", hover_style)
	option_btn.add_theme_stylebox_override("normal", normal_style)
	
	# Font styling if needed
	option_btn.add_theme_font_override("font", BASIS_33)
	option_btn.add_theme_font_size_override("font_size", 28)


func _on_btn_accept_pressed() -> void:
	
	var now = Time.get_datetime_dict_from_system()
	
	var current_month = now.month
	var current_day = now.day
	var current_year = now.year
	
	print("Current month: " + str(current_month))
	print("Selected month: " + str(month.selected + 1))
	
	var month = month.selected + 1
	var day = day.selected + 1
	var year = year_range[year.selected]
	
	var age = current_year - year;
	
	if current_month < month or (current_day < day and current_month == month):
		age -= 1;
	
	if age < 18:
		print("is minor");
		SignalBus.next_scene.emit("res://testtt.tscn");
	elif age >= 18:
		print("is adult");
		SignalBus.next_scene.emit("res://scenes/menu/menu_create_acc_creds.tscn");
	
	print("Final age: " + str(age));
	
	print("BirthDate: " + str(month) + " " + str(day) + " " + str(year) );
	print("Gender: " + selected_gender);


func _on_male_pressed() -> void:
	selected_gender = genders[0]

func _on_female_pressed() -> void:
	selected_gender = genders[1]

func _on_metal_pressed() -> void:
	selected_gender = genders[2]
