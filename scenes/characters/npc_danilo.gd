extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var speed: float = 50.0
var direction: Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
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
		# idle animations based on last movement
		if animated_sprite.animation.begins_with("walk"):
			animated_sprite.play("idle_" + animated_sprite.animation.replace("walk_", ""))
	else:
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0:
				animated_sprite.play("walk_right")
			else:
				animated_sprite.play("walk_left")
		else:
			if velocity.y > 0:
				animated_sprite.play("walk_down")
			else:
				animated_sprite.play("walk_up")


# NPC interaction detection
