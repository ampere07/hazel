extends Label

var time_remaining = 180
var timer_active = true
var is_paused = false

func _ready():
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	show()
	
	add_theme_font_size_override("font_size", 20)
	add_theme_color_override("font_color", Color(1, 1, 1))
	
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.2, 0.2, 0.2, 0.8)
	bg.size = Vector2(120, 40)
	bg.position = Vector2(-10, -5)
	bg.z_index = -1
	add_child(bg)
	
	update_display()

func _process(delta):
	if timer_active and !is_paused:
		time_remaining -= delta
		
		var current_seconds = int(time_remaining)
		if current_seconds != int(time_remaining + delta):
			update_display()
		
		if time_remaining <= 0:
			time_remaining = 0
			timer_active = false
			update_display()
			on_time_up()

func update_display():
	var minutes = floor(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	text = "%02d:%02d" % [minutes, seconds]
	
	if time_remaining <= 30:
		add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		add_theme_font_size_override("font_size", 22)
	elif time_remaining <= 60:
		add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		add_theme_font_size_override("font_size", 21)
	else:
		add_theme_color_override("font_color", Color(1, 1, 1))
		add_theme_font_size_override("font_size", 20)

func on_time_up():
	var game_manager = get_node_or_null("/root/game_manager")
	if game_manager and game_manager.has_method("on_game_over"):
		game_manager.on_game_over()
	else:
		var result = get_tree().change_scene_to_file("res://scenes/GameOverScene.tscn")
		if result != OK:
			push_error("Failed to change to game over scene")

func set_paused(paused):
	is_paused = paused
