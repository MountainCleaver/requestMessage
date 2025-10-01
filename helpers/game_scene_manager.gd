extends Node

# 	this script is responsible for 
# 	changing scenes/levels e.g. switching 
#	maps, outdoor to indoor, game to menu, etc.

#var scene_type : String = "none";

func _ready() -> void:
	SignalBus.next_scene.connect(self._change_scene);

func _change_scene(to: String):
	_deferred_change_scene.call_deferred(to)

func _deferred_change_scene(to:String):
	TransitionFade.transition();
	await SignalBus.on_transition_finished;
	get_tree().change_scene_to_file(to)
	
	#await get_tree().process_frame
	#
	#var root = get_tree().current_scene
	#if root.has_method("get_scene_type"):
		#scene_type = root.get_scene_type()
	#else:
		#scene_type = "none"
#
#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("escape") and scene_type == "game":
		#SignalBus.toggle_pause.emit()
