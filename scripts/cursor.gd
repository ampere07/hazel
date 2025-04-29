extends Area2D

func _ready():
	$Sprite2D.texture = load("res://assets/640px-Plus_symbol.svg.png")
	
	monitoring = true
	monitorable = true

func check_mining_hit():
	var overlapping_bodies = get_overlapping_bodies()
	var overlapping_areas = get_overlapping_areas()
	
	for body in overlapping_bodies:
		if "Door" in body.name:
			print("Mining the door!")
			if body.has_method("on_mine"):
				body.on_mine()
				return
		
	for body in overlapping_bodies:
		if body.has_method("on_mine"):
			body.on_mine()
	
	for area in overlapping_areas:
		if area.has_method("on_mine"):
			area.on_mine()
