extends Node2D

func _ready():
	# Create a dark semi-transparent background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)
	background.size = get_viewport_rect().size
	add_child(background)
	
	# Add Game Over text
	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER"
	game_over_label.add_theme_font_size_override("font_size", 64)
	game_over_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	game_over_label.position = Vector2(get_viewport_rect().size.x / 2 - 180, get_viewport_rect().size.y / 2 - 150)
	add_child(game_over_label)
	
	# Add explanation text
	var explanation = Label.new()
	explanation.text = "Time has run out!"
	explanation.add_theme_font_size_override("font_size", 32)
	explanation.add_theme_color_override("font_color", Color(1, 1, 1))
	explanation.position = Vector2(get_viewport_rect().size.x / 2 - 120, get_viewport_rect().size.y / 2 - 50)
	add_child(explanation)
	
	# Add retry button
	var retry_button = Button.new()
	retry_button.text = "Try Again"
	retry_button.size = Vector2(200, 50)
	retry_button.position = Vector2(get_viewport_rect().size.x / 2 - 100, get_viewport_rect().size.y / 2 + 50)
	retry_button.pressed.connect(_on_retry_pressed)
	add_child(retry_button)
	
	# Add main menu button
	var main_menu_button = Button.new()
	main_menu_button.text = "Main Menu"
	main_menu_button.size = Vector2(200, 50)
	main_menu_button.position = Vector2(get_viewport_rect().size.x / 2 - 100, get_viewport_rect().size.y / 2 + 120)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	add_child(main_menu_button)

func _on_retry_pressed():
	get_tree().change_scene_to_file("res://scenes/GameSceneEasy.tscn")

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")
