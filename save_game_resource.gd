extends Resource
class_name SaveGameResource

@export var current_scene : String = ""
@export var current_act : String = ""
@export var playtime_seconds: int = 0
@export var date_created: int = 0 
@export var finished_scenes : Dictionary = {
	"act_1": [],
	"act_2": [],
	"act_3": [],
	"act_4": [],
	"act_5": [],
	"act_6": []
}
# karma, if negative -> restless |||| if positve -> relief ||| pag zero? tanungin ko si lord. sana odd yung choices
@export var karma : int = 0
@export var given_lola_ising_cash : bool = false

# act and scene : choice 
# "act_1_scene_3" : "restless"/"relief"
# auto decrement/increment sa karma based sa choice
@export var choices : Dictionary = {
	
}
@export var meds_finished_scenes: Dictionary = {}
@export var meds_taken : int = 0

func to_dict() -> Dictionary:
	return {
		"current_scene": current_scene,
		"current_act": current_act,
		"playtime_seconds": playtime_seconds,
		"date_created": date_created,
		"finished_scenes": finished_scenes,
		"karma": karma,
		"given_lola_ising_cash": given_lola_ising_cash,
		"choices": choices,
		"meds_finished_scenes": meds_finished_scenes,
		"meds_taken": meds_taken
	}
