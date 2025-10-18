extends StaticBody2D

@onready var sprite = $Sprite2D
var got = false

func interact():
	if got:
		return
	got = true

	# Change the region to the cleaned version
	sprite.region_rect = Rect2(15.198, 11.404, 0.0, 16.0)
	print("Get key!")
