extends Node3D

var lift_door_countdown = 0
var interacted_door_animation_flag: bool = false
var time_accumulator = 0.0  # Accumulates delta each frame
var seconds_count = 0
var minutes_count = 0
var hours_count = 0
var second_flag = false
var minute_flag = false
var hour_flag = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$env/ceiling/MeshInstance3D.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	delta_to_second(delta)
	
	if second_flag:
		second_flag = false
		$interacts/PC/AudioStreamPlayer3D.stream_paused = true
		
func delta_to_second(delta_1):
	time_accumulator += delta_1
	# When the accumulator reaches or exceeds 1 second
	if time_accumulator >= 1.0:
		seconds_count += 1  # Increment the integer timer
		# Subtract 1 second from the accumulator (or reset to 0 for exact intervals)
		time_accumulator -= 1.0
		second_flag = true
	if seconds_count >= 60:
		seconds_count = 0
		minutes_count += 1
	if minutes_count >= 60:
		hours_count += 1

#--------------------- Function for Mechanisms
func close_or_open_door(door_node_path: String):
	if interacted_door_animation_flag == false:
		var door_node = get_node(door_node_path)
		var anim = get_node(door_node_path + "/AnimationPlayer")
		var sound = get_node(door_node_path + "/AudioStreamPlayer3D")
		if door_node.object_status == "close":
			door_node.prompt_message = "Close"
			door_node.object_status = "open"
			anim.play("open")
			sound.stream = load("res://sounds/open-door-sound.mp3")
		else:
			door_node.object_status = "close"
			door_node.prompt_message = "Open"
			anim.play("close")
			sound.stream = load("res://sounds/close-door-sound.mp3")
		sound.play(0.75)
		interacted_door_animation_flag = true

func turn_on_off_light(lightswitch_node_path: String):
	var lightswitch_node = get_node(lightswitch_node_path)
	var anim = get_node(lightswitch_node_path + "/AnimationPlayer")
	var sound = get_node(lightswitch_node_path + "/AudioStreamPlayer3D")
	var object_status = ""
	if lightswitch_node.object_status == "ON":
		lightswitch_node.prompt_message = "Turn On"
		lightswitch_node.object_status = "OFF"
		object_status = "OFF"
		anim.play("turn_off")
		toggle_lights_in_area(false,lightswitch_node.object_hierachy,object_status)
	else:
		lightswitch_node.prompt_message = "Turn Off"
		lightswitch_node.object_status = "ON"
		object_status = "ON"
		anim.play("turn_on")
		toggle_lights_in_area(true,lightswitch_node.object_hierachy,object_status)
	sound.play()

func toggle_lights_in_area(status: bool,object_hierarchy: String,object_status: String):
	var i = 1
	while true:
		# Construct the light node name, e.g., "relaxing_1", "relaxing_2"
		var light_name = "env/lights/" + object_hierarchy + "_" + str(i) + "/OmniLight3D"
		var light_node = get_node_or_null(light_name)
		# If no light node is found, exit the loop
		if light_node == null:
			break
		# Assume each light node has a method to turn on/off, like "turn_on()" and "turn_off()"
		light_node.visible = status
		
		#multiple switches
		var other_switch_name = "interacts/light_switches/" + object_hierarchy + "_" + str(i)
		var other_switch_node = get_node_or_null(other_switch_name)
		
		if other_switch_node != null:
			other_switch_node.object_status = object_status
			if object_status == "OFF":
				other_switch_node.prompt_message = "Turn Off"
			else:
				other_switch_node.prompt_message = "Turn On"
		i += 1  # Move to the next light node in the sequence

#--------------------- Function for Signals
func _on_lights_interacted(body: Variant) -> void:
	turn_on_off_light(GlobalVar.interactive_node_path)
	
func _on_doors_interacted(body: Variant) -> void:
	close_or_open_door(GlobalVar.interactive_node_path)

func _on_lift_button_interacted(body: Variant) -> void:
	var lift_door_node = get_node(GlobalVar.interactive_node_path)
	var anim = $interacts/doors/lift/AnimationPlayer
	var sound = $interacts/doors/lift/AudioStreamPlayer3D
	
	if interacted_door_animation_flag == false:
		if lift_door_node.object_status == "close":
			lift_door_node.prompt_message = "Close"
			lift_door_node.object_status = "open"
			anim.play("open")
			sound.stream = load("res://sounds/lift_open.mp3")
			sound.play()
		else:
			lift_door_node.prompt_message = "Open"
			lift_door_node.object_status = "close"
			anim.play("close")
			sound.stream = load("res://sounds/lift_close.mp3")
			sound.play()
		interacted_door_animation_flag = true

func _on_doors_animation_player_animation_finished(anim_name: StringName) -> void:
	interacted_door_animation_flag = false
