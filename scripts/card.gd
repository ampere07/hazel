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

func on_mine():
	if not matched and not flipped:
		var can_flip = true
		if game_manager and game_manager.has_method("can_flip"):
			can_flip = game_manager.can_flip
		
		if can_flip:
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
