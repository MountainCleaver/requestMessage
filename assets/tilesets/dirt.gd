extends StaticBody2D

@onready var sprite = $Sprite2D
var cleaned = false

func interact():
	if cleaned:
		return
	cleaned = true

	# Change the region to the cleaned version
	sprite.region_rect = Rect2(50.333, -0.769, 45.453, 32.431)
	print("Dirt cleaned!")
