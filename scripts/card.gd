extends Area2D

signal card_flipped(card)

@export var card_value: int = 0
var flipped: bool = false
var matched: bool = false
var game_manager = null

func _ready():
	$AnimatedSprite2D.play("back")
	
	add_to_group("cards")
	
	await get_tree().process_frame
	game_manager = get_node("/root/game_manager") if has_node("/root/game_manager") else find_game_manager()

func find_game_manager():
	var root = get_tree().root
	for child in root.get_children():
		if child.name.to_lower() == "gamemanager" or child.name.to_lower() == "game_manager":
			return child
	return null

# Add this function to check if this card can be flipped
func can_be_flipped():
	# Already matched or flipped cards can't be flipped
	if matched or flipped:
		return false
	
	# No game manager means we can't check further
	if game_manager == null:
		return true
		
	# Check if game is paused
	if "is_paused" in game_manager and game_manager.is_paused:
		return false
		
	# Check if game allows flipping
	if "can_flip" in game_manager and !game_manager.can_flip:
		return false
		
	# Check if we already have two cards flipped
	if "first_card" in game_manager and "second_card" in game_manager:
		if game_manager.first_card != null and game_manager.second_card != null:
			return false
			
	return true

func on_mine():
	if can_be_flipped():
		flip_to_front()

func flip_to_front():
	$AnimatedSprite2D.play("front" + str(card_value))
	flipped = true
	
	emit_signal("card_flipped", self)

func flip_to_back():
	$AnimatedSprite2D.play("back")
	flipped = false

func set_matched():
	matched = true
	
	modulate = Color(1.0, 1.0, 1.0, 0.7)
