extends Node3D

func _on_play_pressed() -> void:
	var loadingScreen = load("res://scene/loading_screen.tscn")
	GlobalVar.new_scene_path = "res://scene/office_playable_template.tscn"
	get_tree().change_scene_to_packed(loadingScreen)

func _on_option_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	get_tree().quit()
