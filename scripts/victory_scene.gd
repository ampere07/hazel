extends Node2D
@onready var background_music = $BgMusic

func _ready() -> void:
	if has_node("BgMusic"):
		if background_music.stream:
			background_music.stream.loop = true
		
		if not background_music.playing:
			background_music.play()

func _process(_delta: float) -> void:
	pass

func _on_play_game_pressed():
	if has_node("BgMusic"):
		background_music.stop()
		
	get_tree().change_scene_to_file("res://scenes/GameSceneEasy.tscn")

	
func _on_main_menu_pressed():
	if has_node("BgMusic"):
		background_music.stop()
	
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")
