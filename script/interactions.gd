extends RayCast3D

@onready var prompt = $prompt
# Called when the node enters the scene tree for the first time.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	prompt.text = ""
	if is_colliding():
		var collider = get_collider()
		if collider is Interactable:
			prompt.text = collider.get_prompt()
			GlobalVar.interactive_node_path = collider.get_path()
			if Input.is_action_just_pressed(collider.prompt_input):
				collider.interact(owner)
				
