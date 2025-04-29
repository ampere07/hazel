extends StaticBody2D

var game_completed = false
var game_manager = null
var next_scene = ""

func _ready():
	print("Door script initialized!")
	
	determine_next_scene()
	
	call_deferred("find_game_manager")

func _process(_delta):
	if not game_completed and game_manager:
		check_game_completion()

func determine_next_scene():
	var scene_path = get_tree().current_scene.scene_file_path.to_lower()
	
	if "easy" in scene_path:
		next_scene = "res://scenes/GameSceneMedium.tscn"
		print("Door: Currently in EASY level, next is MEDIUM")
	elif "medium" in scene_path:
		next_scene = "res://scenes/GameSceneHard.tscn"
		print("Door: Currently in MEDIUM level, next is HARD")
	elif "hard" in scene_path:
		next_scene = "res://scenes/VictoryScene.tscn"
		print("Door: Currently in HARD level, next is VICTORY scene")
	else:
		next_scene = "res://scenes/GameSceneMedium.tscn"
		print("Door: Unable to determine current level, defaulting to MEDIUM as next")

func find_game_manager():
	game_manager = get_node_or_null("/root/game_manager")
	
	if not game_manager:
		game_manager = get_tree().current_scene.find_child("game_manager", true, false)
		
	if not game_manager:
		var managers = get_tree().get_nodes_in_group("game_manager")
		if managers.size() > 0:
			game_manager = managers[0]
	
	if game_manager:
		print("Door: Found game manager: " + game_manager.name)
		
		if game_manager.has_signal("game_completed"):
			if not game_manager.is_connected("game_completed", Callable(self, "on_game_completed")):
				game_manager.connect("game_completed", Callable(self, "on_game_completed"))
				print("Door: Connected to game_completed signal")
		
		check_game_completion()
	else:
		print("Door: Could not find game manager")
		await get_tree().create_timer(1.0).timeout
		find_game_manager()

func check_game_completion():
	var is_completed = false
	
	if "GAME_COMPLETED_FLAG" in game_manager:
		if game_manager.GAME_COMPLETED_FLAG:
			is_completed = true
			print("Door: Detected completion via GAME_COMPLETED_FLAG")
	
	if "has_completed" in game_manager and game_manager.has_completed:
		is_completed = true
		print("Door: Detected completion via has_completed property")
	
	if game_manager.has_method("is_game_completed"):
		if game_manager.is_game_completed():
			is_completed = true
			print("Door: Detected completion via is_game_completed method")
	
	if "matches_found" in game_manager and "total_pairs" in game_manager:
		if game_manager.matches_found >= game_manager.total_pairs:
			is_completed = true
			print("Door: Detected completion via matches_found comparison")
	
	if get_tree().has_meta("game_completed"):
		is_completed = true
		print("Door: Detected completion via SceneTree metadata")
		
	var coordinator = get_tree().root.find_child("GameCompletedCoordinator", true, false)
	if coordinator:
		is_completed = true
		print("Door: Found GameCompletedCoordinator node")
	
	if is_completed and not game_completed:
		on_game_completed()

func on_game_completed():
	if game_completed:
		return
	
	game_completed = true
	print("Door: Door has been unlocked!")
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 0.5), 0.5)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.5)
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 0.5), 0.5)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.5)

func on_mine():
	print("Door mined! Game completed:", game_completed)
	
	if not game_completed and game_manager:
		check_game_completion()
	
	if game_completed:
		print("Door: Game completed, changing to next scene...")
		print("Door: Next scene path: " + next_scene)
		
		var result = get_tree().change_scene_to_file(next_scene)
		if result == OK:
			print("Door: Scene change successful!")
			return
			
		var fallback_paths = []
		
		if "medium" in next_scene.to_lower():
			fallback_paths = [
				"res://GameSceneMedium.tscn",
				"res://Scenes/GameSceneMedium.tscn",
				"res://scenes/gamescenemedium.tscn",
				"res://gamescenemedium.tscn"
			]
		elif "hard" in next_scene.to_lower():
			fallback_paths = [
				"res://GameSceneHard.tscn",
				"res://Scenes/GameSceneHard.tscn",
				"res://scenes/gamescenehard.tscn",
				"res://gamescenehard.tscn"
			]
		elif "victory" in next_scene.to_lower():
			fallback_paths = [
				"res://VictoryScene.tscn",
				"res://Victory.tscn",
				"res://Scenes/VictoryScene.tscn",
				"res://scenes/victoryscene.tscn",
				"res://victoryscene.tscn",
				"res://victory.tscn"
			]
		
		for path in fallback_paths:
			print("Door: Trying fallback path:", path)
			result = get_tree().change_scene_to_file(path)
			if result == OK:
				print("Door: Scene change successful with fallback path!")
				return
		
		print("Door: All scene change attempts failed!")
		
		print("Door: Listing available scene files:")
		var dir = DirAccess.open("res://")
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tscn"):
					print("- " + file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
	else:
		print("Door: Complete the card matching game first!")
		
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.5, 0.5, 0.5), 0.2)  # Red flash
		tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.2)
