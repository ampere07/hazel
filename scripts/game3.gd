extends Node2D

signal game_completed
signal pause_state_changed(is_paused)  # New signal to notify other nodes about pause state

var first_card = null
var second_card = null
var can_flip = true
var matches_found = 0
var total_pairs = 18
var has_completed = false
var is_paused = false

# Timer variables
@onready var timer_label = $TimerLabel
var time_remaining = 240
var timer_active = true

static var GAME_COMPLETED_FLAG = false

var card_values = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 
				  10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18]

var animation_frames = {
	1: "front1",
	2: "front2",
	3: "front3",
	4: "front4",
	5: "front5",
	6: "front6",
	7: "front7",
	8: "front8",
	9: "front9",
	10: "front10",
	11: "front11",
	12: "front12",
	13: "front13",
	14: "front14",
	15: "front15",
	16: "front16",
	17: "front17",
	18: "front18"
}

var pause_panel
var resume_button
var restart_button
var main_menu_button
var pause_button

var player_character = null
var original_player_position = Vector2.ZERO

func _ready():
	name = "game_manager"
	add_to_group("game_manager")
	
	GAME_COMPLETED_FLAG = false
	
	randomize()
	card_values.shuffle()
	
	initialize_cards()
	
	setup_pause_menu()
	
	call_deferred("find_player_character")
	
	print("Game Manager initialized with " + str(total_pairs) + " pairs for HARD level")
	
	if timer_label:
		print("Found existing TimerLabel, initializing timer...")
		
		if !timer_label.has_node("Background"):
			var timer_bg = ColorRect.new()
			timer_bg.name = "Background"
			timer_bg.size = Vector2(100, 30)
			timer_bg.position = Vector2(-5, -5)
			timer_bg.color = Color(0.2, 0.2, 0.2, 0.8)
			timer_bg.z_index = -1
			timer_label.add_child(timer_bg)
		
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		update_timer_display()
	else:
		print("ERROR: TimerLabel not found in GameSceneHard! Make sure to add a Label node named TimerLabel.")
	
	await get_tree().create_timer(0.1).timeout
	ensure_all_cards_face_down()

func _process(delta):
	if timer_active and !has_completed and !is_paused:
		time_remaining -= delta
		
		var current_seconds = int(time_remaining)
		if current_seconds != int(time_remaining + delta):
			update_timer_display()
		
		if time_remaining <= 0:
			timer_active = false
			time_remaining = 0
			update_timer_display()
			on_game_over()

func update_timer_display():
	if !is_instance_valid(timer_label):
		print("Warning: Timer label is not valid!")
		return
		
	var minutes = floor(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	if time_remaining <= 30:
		timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		timer_label.add_theme_font_size_override("font_size", 22)
	elif time_remaining <= 60:
		timer_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2)) 
		timer_label.add_theme_font_size_override("font_size", 20)
	else:
		timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
		timer_label.add_theme_font_size_override("font_size", 18)

func on_game_over():
	print("Game Over! Time has run out!")
	can_flip = false
	
	var result = get_tree().change_scene_to_file("res://scenes/GameOverScene.tscn")
	if result != OK:
		print("Failed to change to game over scene. Trying alternatives...")
		var alternative_paths = [
			"res://GameOverScene.tscn",
			"res://Scenes/GameOverScene.tscn",
			"res://scenes/gameover.tscn",
			"res://gameover.tscn"
		]
		
		for path in alternative_paths:
			result = get_tree().change_scene_to_file(path)
			if result == OK:
				print("Successfully changed to: " + path)
				return
		
		print("Could not find game over scene!")

func find_player_character():
	var characters = get_tree().get_nodes_in_group("player")
	if characters.size() > 0:
		player_character = characters[0]
		original_player_position = player_character.position
		print("Found player character in 'player' group")
		return
	
	var common_names = ["Player", "Character", "PlayerCharacter", "Cursor", "MainCharacter"]
	for node_name in common_names:
		var node = get_tree().current_scene.find_child(node_name, true, false)
		if node:
			player_character = node
			original_player_position = player_character.position
			print("Found player character with name: " + node_name)
			return
	
	var scene_nodes = get_tree().get_nodes_in_group("")
	for node in scene_nodes:
		if "player" in node.name.to_lower() or "character" in node.name.to_lower() or "cursor" in node.name.to_lower():
			player_character = node
			original_player_position = player_character.position
			print("Found player character with name containing 'player' or 'character': " + node.name)
			return
	
	print("Could not find player character")

func setup_pause_menu():
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "||"
	pause_button.size = Vector2(30, 30)
	pause_button.position = Vector2(20, 20)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	pause_button.add_theme_stylebox_override("normal", style)
	
	# White text
	pause_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	pause_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	pause_button.add_theme_color_override("font_pressed_color", Color(0.8, 0.8, 0.8, 1))
	
	# Connect signal and add to scene
	pause_button.pressed.connect(_on_pause_button_pressed)
	add_child(pause_button)
	
	# Create pause panel
	pause_panel = Panel.new()
	pause_panel.name = "PausePanel"
	pause_panel.size = Vector2(300, 250)
	pause_panel.position = Vector2(get_viewport_rect().size.x/2 - 150, get_viewport_rect().size.y/2 - 125)
	
	# Panel styling
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.5, 0.5, 0.5)
	pause_panel.add_theme_stylebox_override("panel", panel_style)
	
	pause_panel.visible = false
	add_child(pause_panel)
	
	# Create panel title
	var panel_title = Label.new()
	panel_title.text = "PAUSED"
	panel_title.position = Vector2(110, 30)
	panel_title.add_theme_font_size_override("font_size", 24)
	panel_title.add_theme_color_override("font_color", Color(1, 1, 1))
	pause_panel.add_child(panel_title)
	
	# Create Resume Button
	resume_button = Button.new()
	resume_button.text = "Resume"
	resume_button.size = Vector2(200, 40)
	resume_button.position = Vector2(50, 80)
	resume_button.pressed.connect(_on_resume_button_pressed)
	pause_panel.add_child(resume_button)
	
	# Create Restart Button
	restart_button = Button.new()
	restart_button.text = "Restart"
	restart_button.size = Vector2(200, 40)
	restart_button.position = Vector2(50, 130)
	restart_button.pressed.connect(_on_restart_button_pressed)
	pause_panel.add_child(restart_button)
	
	# Create Main Menu Button
	main_menu_button = Button.new()
	main_menu_button.text = "Main Menu"
	main_menu_button.size = Vector2(200, 40)
	main_menu_button.position = Vector2(50, 180)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	pause_panel.add_child(main_menu_button)
	
	# Style all buttons
	for button in [resume_button, restart_button, main_menu_button]:
		var button_style = StyleBoxFlat.new()
		button_style.bg_color = Color(0.3, 0.3, 0.3)
		button_style.corner_radius_top_left = 5
		button_style.corner_radius_top_right = 5
		button_style.corner_radius_bottom_left = 5
		button_style.corner_radius_bottom_right = 5
		
		button.add_theme_stylebox_override("normal", button_style)
		button.add_theme_color_override("font_color", Color(1, 1, 1))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	
		# Hover style
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.4, 0.4, 0.4)
		hover_style.corner_radius_top_left = 5
		hover_style.corner_radius_top_right = 5
		hover_style.corner_radius_bottom_left = 5
		hover_style.corner_radius_bottom_right = 5
		
		button.add_theme_stylebox_override("hover", hover_style)
	
	pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	main_menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_pause_button_pressed():
	print("Pause button pressed")
	pause_game()

func _on_resume_button_pressed():
	print("Resume button pressed")
	resume_game()

func _on_restart_button_pressed():
	print("Restart button pressed")
	resume_game()
	reset_game() 
	reset_player_position()

func _on_main_menu_button_pressed():
	print("Main menu button pressed")
	resume_game()
	var result = get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")
	if result != OK:
		print("Failed to change to main menu scene. Trying alternatives...")
		var alternative_paths = [
			"res://MainMenuScene.tscn",
			"res://Scenes/MainMenuScene.tscn",
			"res://scenes/MainMenu.tscn",
			"res://MainMenu.tscn"
		]
		
		for path in alternative_paths:
			result = get_tree().change_scene_to_file(path)
			if result == OK:
				print("Successfully changed to: " + path)
				return
		
		print("Could not find main menu scene. Listing available scenes:")
		var dir = DirAccess.open("res://")
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tscn"):
					print("- " + file_name)
				file_name = dir.get_next()
			dir.list_dir_end()

func pause_game():
	print("Pausing game")
	is_paused = true
	pause_panel.visible = true
	# Disable card interaction
	can_flip = false
	
	emit_signal("pause_state_changed", true)
	
	if player_character:
		if "can_move" in player_character:
			player_character.can_move = false
		if "enabled" in player_character:
			player_character.enabled = false
		if "active" in player_character:
			player_character.active = false
		
		if player_character.has_node("AnimationPlayer"):
			var animator = player_character.get_node("AnimationPlayer")
			animator.pause()
		if player_character.has_node("AnimatedSprite2D"):
			var sprite = player_character.get_node("AnimatedSprite2D")
			if sprite.is_playing():
				sprite.pause()
	
	get_tree().paused = true

func resume_game():
	print("Resuming game")
	is_paused = false
	pause_panel.visible = false
	if !has_completed:
		can_flip = true
	
	emit_signal("pause_state_changed", false)
	
	if player_character:
		if "can_move" in player_character:
			player_character.can_move = true
		if "enabled" in player_character:
			player_character.enabled = true
		if "active" in player_character:
			player_character.active = true
		
		if player_character.has_node("AnimationPlayer"):
			var animator = player_character.get_node("AnimationPlayer")
			animator.play()
		if player_character.has_node("AnimatedSprite2D"):
			var sprite = player_character.get_node("AnimatedSprite2D")
			sprite.play()
	
	get_tree().paused = false

func reset_player_position():
	if player_character and original_player_position != Vector2.ZERO:
		print("Resetting player position to: " + str(original_player_position))
		player_character.position = original_player_position
		
		if "velocity" in player_character:
			player_character.velocity = Vector2.ZERO
		if "linear_velocity" in player_character:
			player_character.linear_velocity = Vector2.ZERO

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if is_paused:
			resume_game()
		else:
			pause_game()

func initialize_cards():
	var cards = get_tree().get_nodes_in_group("cards")
	var card_index = 0
	
	for card in cards:
		if card_index < card_values.size():
			card.card_value = card_values[card_index]
			
			assign_card_front_animation(card, card_values[card_index])
			
			card.connect("card_flipped", Callable(self, "_on_card_flipped"))
			card_index += 1
	
	print("Initialized " + str(cards.size()) + " cards")

func assign_card_front_animation(card, value):
	if not value in animation_frames:
		print("Warning: Card value " + str(value) + " doesn't have a corresponding animation")
		return
		
	var animation_name = animation_frames[value]
	
	if card.has_method("set_front_animation"):
		card.call("set_front_animation", animation_name)
		print("Assigned card front animation: " + animation_name)
		return
	
	if "front_animation" in card:
		card.front_animation = animation_name
		print("Assigned card.front_animation property: " + animation_name)

func ensure_all_cards_face_down():
	var cards = get_tree().get_nodes_in_group("cards")
	
	for card in cards:
		# Reset to back-facing
		if card.has_method("flip_to_back"):
			card.flip_to_back()
		elif card.has_node("AnimatedSprite2D"):
			var sprite = card.get_node("AnimatedSprite2D")
			if sprite.has_method("play"):
				sprite.play("back")
	
	print("All cards set to face down position")

func set_card_front_animation(card, value):
	if not value in animation_frames:
		print("Warning: Card value " + str(value) + " doesn't have a corresponding animation")
		return
		
	var animation_name = animation_frames[value]
	
	if card.has_method("set_front_animation"):
		card.call("set_front_animation", animation_name)
		print("Set card animation via set_front_animation method: " + animation_name)
		return
	
	if "front_animation" in card:
		card.front_animation = animation_name
		print("Set card.front_animation property: " + animation_name)
		
	if card.has_node("AnimatedSprite2D"):
		var sprite = card.get_node("AnimatedSprite2D")
		
		if sprite.has_method("play"):
			sprite.play(animation_name)
			print("Playing animation directly: " + animation_name)

func _on_card_flipped(card):
	if !can_flip or is_paused:
		return
		
	if first_card == null:
		first_card = card
	elif second_card == null and card != first_card:
		second_card = card
		can_flip = false
		
		if first_card.card_value == second_card.card_value:
			await get_tree().create_timer(0.5).timeout
			
			first_card.set_matched()
			second_card.set_matched()
			
			matches_found += 1
			print("Match found! Total matches: " + str(matches_found) + "/" + str(total_pairs))
			
			# Reset for next pair
			first_card = null
			second_card = null
			can_flip = true
			
			if matches_found >= total_pairs and !has_completed:
				await get_tree().create_timer(0.5).timeout
				on_game_completed()
		else:
			await get_tree().create_timer(1.0).timeout
			
			first_card.flip_to_back()
			second_card.flip_to_back()
			
			first_card = null
			second_card = null
			can_flip = true

func on_game_completed():
	print("Congratulations! You found all matches!")
	has_completed = true
	timer_active = false  # Stop the timer when game is completed
	
	GAME_COMPLETED_FLAG = true
	print("Set static GAME_COMPLETED_FLAG = true")
	
	get_tree().set_meta("game_completed", true)
	print("Set SceneTree metadata: game_completed = true")
	
	var coordinator = Node.new()
	coordinator.name = "GameCompletedCoordinator"
	coordinator.set_meta("game_completed", true)
	get_tree().root.add_child(coordinator)
	print("Added GameCompletedCoordinator node")
	
	emit_signal("game_completed")
	print("Game completed signal emitted")
	
	notify_door()
	
	show_game_completed_effects()
	
	print_rich("[color=yellow]The door is now unlocked! Mine the door to proceed to the VICTORY screen![/color]")

func notify_door():
	var door = get_tree().current_scene.find_child("Door", true, false)
	
	if door:
		print("Game Manager: Found door at " + str(door.get_path()))
		
		if door.has_method("on_game_completed"):
			door.call("on_game_completed")
			print("Called door.on_game_completed()")
		
		door.set("game_completed", true)
		print("Set door.game_completed = true directly")
		
		door.set("next_scene", get_next_scene_path())
		print("Set door.next_scene for next level")
		
		var tween = create_tween()
		tween.tween_property(door, "modulate", Color(1.5, 1.5, 0.5), 0.5)
		tween.tween_property(door, "modulate", Color(1.0, 1.0, 1.0), 0.5)
		tween.tween_property(door, "modulate", Color(1.5, 1.5, 0.5), 0.5)
		tween.tween_property(door, "modulate", Color(1.0, 1.0, 1.0), 0.5)
	else:
		print("Game Manager: Door not found!")
		
		var potential_doors = []
		for node in get_tree().get_nodes_in_group(""):
			if "door" in node.name.to_lower():
				potential_doors.append(node)
		
		print("Found " + str(potential_doors.size()) + " potential door nodes")
		for pot_door in potential_doors:
			print(" - " + pot_door.name + " at " + str(pot_door.get_path()))
			if pot_door.has_method("on_game_completed"):
				pot_door.call("on_game_completed")
				print("Called potential door's on_game_completed()")

func get_next_scene_path():
	return "res://scenes/VictoryScene.tscn"

func is_game_completed():
	return has_completed || matches_found >= total_pairs

func show_game_completed_effects():
	var cards = get_tree().get_nodes_in_group("cards")
	
	for card in cards:
		var tween = create_tween()
		tween.tween_property(card, "modulate", Color(1.5, 1.5, 1.5), 0.5)
		tween.tween_property(card, "modulate", Color(1, 1, 1, 0.7), 0.5)

func reset_game():
	first_card = null
	second_card = null
	can_flip = true
	matches_found = 0
	has_completed = false
	GAME_COMPLETED_FLAG = false
	
	# Reset timer
	time_remaining = 240
	timer_active = true
	update_timer_display()
	
	card_values.shuffle()
	
	var cards = get_tree().get_nodes_in_group("cards")
	var card_index = 0
	
	for card in cards:
		card.matched = false
		card.modulate = Color.WHITE
		card.flip_to_back()
		card.card_value = card_values[card_index]
		
		assign_card_front_animation(card, card_values[card_index])
		
		card_index += 1
	
	ensure_all_cards_face_down()
