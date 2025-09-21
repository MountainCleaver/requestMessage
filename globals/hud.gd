extends CanvasLayer

@onready var v_box_container: VBoxContainer = $Control/objectives/MarginContainer/VBoxContainer
@onready var objectives_panel: Panel = $Control/objectives;
const BASIS_33 = preload("res://assets/fonts/basis33.ttf");
@onready var objective_animation: AnimationPlayer = $objective_animation

func new_objective(obj_ID: int, new_objective: String) -> void:
	_create_objective_node(obj_ID, new_objective);

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
	objective_animation.play("slide_in");
