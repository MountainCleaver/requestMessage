extends Node2D

@onready var area_2d: Area2D = $Area2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var skip_sprite: Sprite2D = $skip_sprite
@onready var label: RichTextLabel = $Label

var breathe_in: bool = true
var started: bool = false
var playing: bool = false

var is_mouse_down: bool = false
var skipped: bool = false

var progress := {
	"breathe_in": 0.0,
	"breathe_out": 0.0
}

var count : int = 0

func _ready() -> void:
	skip_sprite.hide()
	area_2d.input_event.connect(_on_area_input_event)
	animation_player.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	if not started:
		return

	label.text = "click and hold" if breathe_in else "release"

func _on_area_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_mouse_down = true
			if not started:
				started = true
			if breathe_in:
				_play_animation("breathe_in")
			else:
				_pause_animation("breathe_out")

# catch mouse release globally (even if outside the area)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and is_mouse_down:
			is_mouse_down = false
			if not breathe_in:
				_play_animation("breathe_out")
			else:
				_pause_animation("breathe_in")

func _play_animation(anim: String) -> void:
	if playing:
		return
	playing = true
	animation_player.play(anim)
	animation_player.seek(progress[anim], true)

func _pause_animation(anim: String) -> void:
	progress[anim] = animation_player.current_animation_position
	animation_player.pause()
	playing = false

func _on_animation_finished(anim_name: String) -> void:
	count += 1
	if count == 2:
		skip_sprite.show()
	elif count >= 6:
		SignalBus.mini_game_done.emit(self) 
		print("mini game is done")
		return

	playing = false
	breathe_in = not breathe_in
	progress[anim_name] = 0.0  # reset progress when fully done

func _on_skip_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		skipped = true
		print("Skipped mini game")
		SignalBus.mini_game_done.emit(self) 
