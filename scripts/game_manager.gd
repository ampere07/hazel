extends Node2D

signal game_completed

var first_card = null
var second_card = null
var can_flip = true
var matches_found = 0
var total_pairs = 3
var has_completed = false
var current_level = "easy"
var next_level = "medium"

static var GAME_COMPLETED_FLAG = false

var card_values = []

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

func _ready():
	name = "game_manager"
	add_to_group("game_manager")
	
	GAME_COMPLETED_FLAG = false
	
	determine_current_level()
	
	initialize_cards()
	
	print("Game Manager initialized with " + str(total_pairs) + " pairs for " + current_level + " level")
	print("Next level will be: " + next_level)

func determine_current_level():
	var scene_path = get_tree().current_scene.scene_file_path.to_lower()
	
	if "easy" in scene_path:
		current_level = "easy"
		next_level = "medium"
		total_pairs = 3
		card_values = [1, 1, 2, 2, 3, 3]
		print("Game Manager: Detected EASY level")
	elif "medium" in scene_path:
		current_level = "medium"
		next_level = "hard"
		total_pairs = 6
		card_values = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]
		print("Game Manager: Detected MEDIUM level")
	elif "hard" in scene_path:
		current_level = "hard"
		next_level = "victory"
		total_pairs = 9
		card_values = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9]
		print("Game Manager: Detected HARD level, next is VICTORY")
	else:
		current_level = "unknown"
		next_level = "medium"
		total_pairs = 3
		card_values = [1, 1, 2, 2, 3, 3]
		print("Game Manager: Unknown level, defaulting to EASY setup")
	
	randomize()
	card_values.shuffle()

func initialize_cards():
	var cards = get_tree().get_nodes_in_group("cards")
	var card_index = 0
	
	for card in cards:
		if card_index < card_values.size():
			card.card_value = card_values[card_index]
			
			set_card_front_animation(card, card_values[card_index])
			
			card.connect("card_flipped", Callable(self, "_on_card_flipped"))
			card_index += 1
	
	print("Initialized " + str(cards.size()) + " cards")

func set_card_front_animation(card, value):
	if card.has_method("set_front_animation") and value in animation_frames:
		card.call("set_front_animation", animation_frames[value])
		print("Set card animation via method: " + animation_frames[value])
	elif card.has_node("AnimatedSprite2D"):
		var sprite = card.get_node("AnimatedSprite2D")
		
		if value in animation_frames:
			card.front_animation = animation_frames[value]
			print("Set card.front_animation = " + animation_frames[value])
			
			if sprite.has_method("play"):
				sprite.play(animation_frames[value])

func _on_card_flipped(card):
	if !can_flip:
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
	
	if current_level == "hard":
		print_rich("[color=yellow]The door is now unlocked! Mine the door to proceed to the VICTORY screen![/color]")
	else:
		print_rich("[color=yellow]The door is now unlocked! Mine the door to proceed to the next level.[/color]")
	
	set_process_input(true)

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
		print("Set door.next_scene to path for " + next_level)
		
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
	if next_level == "medium":
		return "res://scenes/GameSceneMedium.tscn"
	elif next_level == "hard":
		return "res://scenes/GameSceneHard.tscn"
	elif next_level == "victory":
		return "res://scenes/VictoryScene.tscn"
	else:
		return "res://scenes/GameSceneMedium.tscn"

func _input(event):
	if has_completed:
		if event.is_action_pressed("ui_cancel"):
			print("Emergency scene transition triggered")
			var door = get_tree().current_scene.find_child("Door", true, false)
			if door and door.has_method("on_mine"):
				door.call("on_mine")
		
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
			var cursor = get_tree().current_scene.find_child("Cursor", true, false)
			var door = get_tree().current_scene.find_child("Door", true, false)
			
			if cursor and door:
				var cursor_pos = cursor.global_position
				var door_pos = door.global_position
				var distance = cursor_pos.distance_to(door_pos)
				
				print("Distance from cursor to door: " + str(distance))
				if distance < 150:
					print("Mining near door after game completion!")
					if door.has_method("on_mine"):
						door.call("on_mine")

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
	
	card_values.shuffle()
	
	var cards = get_tree().get_nodes_in_group("cards")
	var card_index = 0
	
	for card in cards:
		card.matched = false
		card.modulate = Color.WHITE
		card.flip_to_back()
		card.card_value = card_values[card_index]
		
		set_card_front_animation(card, card_values[card_index])
		
		card_index += 1
