extends Control

@onready var pause_menu = $pause_menu
var pause_flag = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Engine.time_scale = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_game()
		GlobalVar.pause_status = !GlobalVar.pause_status

func pause_game():
	if pause_flag:
		pause_menu.visible = false
		Engine.time_scale = 1
	else:
		pause_menu.visible = true
		Engine.time_scale = 0
		
	pause_flag = !pause_flag

func _on_resume_pressed() -> void:
	pause_game()
	GlobalVar.pause_status = !GlobalVar.pause_status

func _on_option_pressed() -> void:
	pass # Replace with function body.

func _on_exit_pressed() -> void:
	var loadingScreen = load("res://scene/loading_screen.tscn")
	GlobalVar.new_scene_path = "res://scene/main_menu.tscn"
	GlobalVar.pause_status = false
	Engine.time_scale = 1
	get_tree().change_scene_to_packed(loadingScreen)
