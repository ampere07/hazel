extends Node2D

signal game_completed

var first_card = null
var second_card = null
var can_flip = true
var matches_found = 0
var total_pairs = 3
var has_completed = false

static var GAME_COMPLETED_FLAG = false

var card_values = [1, 1, 2, 2, 3, 3]

var animation_frames = {
	1: "front1",
	2: "front2",
	3: "front3",
	4: "front4",
	5: "front5",
	6: "front6"
}

func _ready():
	name = "game_manager"
	add_to_group("game_manager")
	
	GAME_COMPLETED_FLAG = false
	
	randomize()
	card_values.shuffle()
	
	initialize_cards()
	
	print("Game Manager initialized with " + str(total_pairs) + " pairs for EASY level")
	
	await get_tree().create_timer(0.1).timeout
	ensure_all_cards_face_down()

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
	
	print_rich("[color=yellow]The door is now unlocked! Mine the door to proceed to the MEDIUM level.[/color]")

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
	return "res://scenes/GameSceneMedium.tscn"

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
		
		assign_card_front_animation(card, card_values[card_index])
		
		card_index += 1
	
	ensure_all_cards_face_down()
