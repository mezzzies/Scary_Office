extends Node

var interactive_node_path = ""
var new_scene_path = ""
var pause_status : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interactive_node_path = ""

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)
