extends Control

@onready var exit: Button = %exit
@onready var uploader: Button = $Panel/HBoxContainer/SCREENSHOT/UPLOADER
@onready var file_dialog: FileDialog = $Panel/HBoxContainer/SCREENSHOT/UPLOADER/FileDialog
@onready var ss_preview: TextureRect = $Panel/ss_preview
@onready var bug_type: OptionButton = $Panel/HBoxContainer/BUG_TYPE/BUG_TYPE

const BASIS_33 = preload("res://assets/fonts/basis33.ttf");

@onready var bug_type_popup = bug_type.get_popup();

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	file_dialog.filters = ["*.png ; PNG Images", "*.jpg ; JPEG Images"]
	file_dialog.file_selected.connect(_on_file_selected)
	
	_style_popup(bug_type_popup);
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_on_exit_pressed();


func _on_exit_pressed() -> void:
	SignalBus.exit_overlay.emit();
	queue_free();


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
