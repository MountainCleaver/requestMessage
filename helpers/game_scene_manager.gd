extends Node

# 	this script is responsible for 
# 	changing scenes/levels e.g. switching 
#	maps, outdoor to indoor, game to menu, etc.


func _ready() -> void:
	SignalBus.next_scene.connect(self._change_scene);

func _change_scene(to: String):
	_deferred_change_scene.call_deferred(to)

func _deferred_change_scene(to:String):
	TransitionFade.transition();
	await SignalBus.on_transition_finished;
	get_tree().change_scene_to_file(to)
