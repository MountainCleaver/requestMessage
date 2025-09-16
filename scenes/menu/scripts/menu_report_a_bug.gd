extends Control

@onready var exit: Button = %exit

@onready var uploader: Button = $Panel/HBoxContainer/SCREENSHOT/UPLOADER
@onready var file_dialog: FileDialog = $Panel/HBoxContainer/SCREENSHOT/UPLOADER/FileDialog
@onready var ss_preview: TextureRect = $Panel/ss_preview
@onready var bug_type: OptionButton = $Panel/HBoxContainer/BUG_TYPE/BUG_TYPE

@onready var text_edit: TextEdit = $Panel/TextEdit


@onready var submit: Button = $Panel/BUTTONS/SUBMIT
@onready var clear: Button = $Panel/BUTTONS/CLEAR

@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog

const BASIS_33 = preload("res://assets/fonts/basis33.ttf");

@onready var bug_type_popup = bug_type.get_popup();

var pending_action : String = "";

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	file_dialog.filters = ["*.png ; PNG Images", "*.jpg ; JPEG Images"]
	file_dialog.file_selected.connect(_on_file_selected)
	
	_style_popup(bug_type_popup);

func _process(delta: float) -> void:
	if text_edit.text == "":
		submit.disabled = true;
	else:
		submit.disabled = false;

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_show_confirm_dialog("exit");


func _on_exit_pressed() -> void:
	_show_confirm_dialog("exit");


func _on_uploader_pressed() -> void:
	file_dialog.visible = true;

func _on_file_selected(path: String):
	uploader.text = path;
	var image = Image.load_from_file(path);
	var tex = ImageTexture.create_from_image(image);
	ss_preview.texture = tex;


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


func _on_submit_pressed() -> void:
	_show_confirm_dialog("submit");

func _on_clear_pressed() -> void:
	_show_confirm_dialog("clear")

func _show_confirm_dialog(actions: String):
	
	if actions == "submit":
		_dialog_config("submit", "Are you sure you want to submit this report?")
	elif actions == "clear":
		_dialog_config("clear", "Are you sure you want to clear this report?")
	elif actions == "exit":
		if !text_edit.text.is_empty():
			_dialog_config("exit", "Exitting will discard the report.");
		else:
			SignalBus.exit_overlay.emit();
			queue_free();
			

func _dialog_config(action: String, dialog_text: String):
	pending_action = action;
	confirmation_dialog.dialog_text = dialog_text;
	confirmation_dialog.popup_centered();

func _on_confirmation_dialog_confirmed() -> void:
	_confirm_action();

func _confirm_action() -> void:
	if pending_action == "submit":
		var content : String = text_edit.text;
		var bug_type : String = bug_type.get_item_text( bug_type.selected ) ;
		
		#this values are ready to be sent to the database
		print("Content : " + content);
		print("Bug type: " + bug_type);
		
		_clear_report_fields();

	elif pending_action == "clear":
		print("clear the report");
		_clear_report_fields();
		
	elif pending_action == "exit":
		if !text_edit.text.is_empty():
			SignalBus.exit_overlay.emit();
			queue_free();

func _clear_report_fields() -> void:
	text_edit.text = "";
	bug_type.select(0);
	ss_preview.texture = null;
