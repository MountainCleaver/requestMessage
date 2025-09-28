extends CanvasLayer

@onready var v_box_container: VBoxContainer = $Control/objectives/MarginContainer/VBoxContainer
@onready var objectives_panel: Panel = $Control/objectives;
const BASIS_33 = preload("res://assets/fonts/basis33.ttf");
@onready var hud_animations: AnimationPlayer = $hud_animations


@onready var lock_screen: Control = $Control/phone/MarginContainer/lock_screen

var phone_showing = false;

func clear_objectives() -> void:
	for obj in v_box_container.get_children():
		obj.queue_free();

func new_objective(obj_ID: int, new_objective_text: String) -> void:
	_create_objective_node(obj_ID, new_objective_text);

func done_objective(obj_ID: int, objective: String) -> void: # objective = current objective, done_objective = same but with strikthough
	
	var objectives_nodes = v_box_container.get_children() as Array[RichTextLabel];
	for obj in objectives_nodes:
		if obj.get_meta("ID") == obj_ID:
			obj.text = "[✔]" + objective;

func _create_objective_node(objective_ID: int, objective_string: String) -> void:
	var objective_node = RichTextLabel.new();
	objective_node.bbcode_enabled = true;
	objective_node.fit_content = true;
	objective_node.autowrap_mode = TextServer.AUTOWRAP_WORD;
	
	objective_node.add_theme_font_override("normal_font", BASIS_33);
	objective_node.add_theme_font_size_override("normal_font_size", 24);
	objective_node.add_theme_color_override("default_color", Color.BLACK);
	
	objective_node.add_theme_color_override("font_strikethrough_color", Color.RED);
	objective_node.add_theme_constant_override("font_strikethrough_width", 3);

	objective_node.text = "[ ]" + str(objective_string);
	objective_node.set_meta("ID", objective_ID)
	
	v_box_container.add_child(objective_node);

func show_objectives() -> void:
	objectives_panel.visible = true;
	objective_intro_anim();

func hide_objectives() -> void:
	objectives_panel.visible = false;

func objective_intro_anim() -> void:
	hud_animations.play("objective_in");

func objective_outro_anim()-> void:
	hud_animations.play("objective_out");
	SignalBus.phone_out.emit();

func phone_intro() -> void:
	hud_animations.play("phone_in");
	SignalBus.phone_in.emit();
func phone_outro() -> void:
	hud_animations.play("phone_out");
	SignalBus.phone_out.emit();

func toggle_phone() -> void:
	if phone_showing:
		phone_outro()
		phone_showing = false
	else:
		phone_intro()
		phone_showing = true
