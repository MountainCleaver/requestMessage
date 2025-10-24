extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var speed: float = 50.0
var direction: Vector2 = Vector2.ZERO

# remember last horizontal and vertical facings
var last_horizontal: String = "right"  # "left" or "right"
var last_vertical: String = "down"     # "up" or "down"

func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		# prevents tiny pushes
		move_and_collide(Vector2.ZERO)
	else:
		velocity = direction * speed
		move_and_slide()

	_update_animation()

func _update_animation() -> void:
	if velocity == Vector2.ZERO:
		# idle: choose up/down idle based on last vertical movement
		animated_sprite.play("idle_" + last_vertical)
		return

	# determine dominant axis
	if abs(velocity.x) > abs(velocity.y):
		# horizontal movement
		if velocity.x > 0:
			last_horizontal = "right"
			animated_sprite.play("walk_right")
		else:
			last_horizontal = "left"
			animated_sprite.play("walk_left")
	else:
		# mostly vertical movement -> reuse last horizontal walk animation
		if velocity.y > 0:
			last_vertical = "down"
		else:
			last_vertical = "up"

		# play the walk animation corresponding to last horizontal facing
		if last_horizontal == "right":
			animated_sprite.play("walk_right")
		else:
			animated_sprite.play("walk_left")
