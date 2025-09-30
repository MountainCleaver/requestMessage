extends Resource
class_name SaveGameResource

@export var current_scene : String = ""
@export var current_act : String = ""
@export var finished_scenes : Dictionary = {
	"act_1": [],
	"act_2": [],
	"act_3": [],
	"act_4": [],
	"act_5": [],
	"act_6": []
}
@export var relief : int = 0
@export var restless : int = 0
@export var given_lola_ising_flashlight : bool = false

@export var scene_3_choice : String = "";
