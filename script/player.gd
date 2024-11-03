extends CharacterBody3D

const JUMP_VELOCITY = 4.5
const WALK_SPEED = 3.0
const SPRINT_SPEED = 7.0
const SPRINT_STAMINA_DRAIN_VAL = 25
#const JUMP_STAMINA_DRAIN_VAL = 20
const STAMINA_RECOVERY_VAL = 20

enum PLAYER_STATE {
	IDLE,
	SITTING,
	WALKING,
	SPRINTING
}

@onready var footstep_audio : AudioStreamPlayer3D = get_node(NodePath("AudioStreamPlayer3D"))

var speed
var stamina_gauge
var moving_flag: bool = false
var walking_sound_flag: bool = false
var player_state
var last_player_position: Vector3
var interacted_obj_rotation_deg: Vector3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	speed = WALK_SPEED
	stamina_gauge = get_node("/root/" + get_tree().current_scene.name + "/UI/stamina_gauge")
	$male_casual/AnimationTree.set("parameters/MAIN/blend_position",Vector2(0,0))
	last_player_position = global_position
	player_state = PLAYER_STATE.IDLE
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Create and assign a PhysicsMaterial to reduce friction
#	var material = PhysicsMaterial.new()
#	material.friction = 0.1  # Lower friction to prevent sticking
#	material.bounce = 0.0    # Optional: Set bounce if needed
#	$CollisionShape3D.material_override = material

#	Camera Control
func _input(event: InputEvent) -> void:
	var min_deg
	var max_deg
	if event is InputEventMouseMotion:
		if player_state == PLAYER_STATE.SITTING:
			$".".rotate_y(-event.relative.x * 0.005)
			$Head.rotate_x(-event.relative.y * 0.005)
			$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-70),deg_to_rad(90))
			$".".rotation.y = clamp($".".rotation.y, deg_to_rad(interacted_obj_rotation_deg.y - 30) \
			,deg_to_rad(interacted_obj_rotation_deg.y + 30))
			pass
		else:
			$".".rotate_y(-event.relative.x * 0.005)
			$Head.rotate_x(-event.relative.y * 0.005)
			$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-90),deg_to_rad(90))

func _process(delta):
	# Stamina Show
	if stamina_gauge.value < (stamina_gauge.max_value):
		stamina_gauge.visible = true
	else:
		stamina_gauge.visible = false
	
	# Handle Sprint.
	if speed == SPRINT_SPEED and stamina_gauge.value > (stamina_gauge.min_value + 10):
		stamina_gauge.value = stamina_gauge.value - SPRINT_STAMINA_DRAIN_VAL * delta
	elif speed == WALK_SPEED and stamina_gauge.value < stamina_gauge.max_value:
		stamina_gauge.value = stamina_gauge.value + STAMINA_RECOVERY_VAL * delta
		if stamina_gauge.value >= stamina_gauge.max_value:
			stamina_gauge.value = stamina_gauge.max_value
	elif speed == SPRINT_SPEED and stamina_gauge.value <= (stamina_gauge.min_value + 10):
		speed = WALK_SPEED
	else:
		pass
		
	if Input.is_action_just_pressed("flashlight"):
		if $Head/flashlight.visible == false:
			$Head/flashlight.visible = true
		else:
			$Head/flashlight.visible = false

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	# Handle Jump.
#	if Input.is_action_just_pressed("jump") and \
#	is_on_floor() and \
#	stamina_gauge.value > (stamina_gauge.min_value + 30):
#		stamina_gauge.value -= JUMP_STAMINA_DRAIN_VAL
#		velocity.y = JUMP_VELOCITY
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if input_dir.x == 0 and input_dir.y == 0:
		footstep_audio.stop()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if Input.is_action_just_pressed("sprint") and \
		is_on_floor() and \
		stamina_gauge.value > (stamina_gauge.min_value + 30):
			speed = SPRINT_SPEED
		elif Input.is_action_just_released("sprint") and is_on_floor():
			speed = WALK_SPEED
		else:
			pass
		moving_flag = true
		player_state = PLAYER_STATE.WALKING
	else:
		moving_flag = false
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	if $male_casual/AnimationPlayer.is_playing() and \
	player_state == PLAYER_STATE.WALKING:
		$male_casual/AnimationPlayer.stop()
		global_position = last_player_position
		
	# Smoothly transition the animation blend position
	var current_blend = $male_casual/AnimationTree.get("parameters/MAIN/blend_position")
	var input_dir_x = input_dir.x
	var input_dir_y = -input_dir.y
	if speed == WALK_SPEED and moving_flag == true:
		input_dir_y = input_dir_y * 0.66
		player_state = PLAYER_STATE.WALKING
	elif speed == SPRINT_SPEED and moving_flag == true:
		input_dir_y = input_dir_y
		player_state = PLAYER_STATE.SPRINTING
	elif moving_flag == false and \
	$male_casual/AnimationPlayer.current_animation != "sit":
		player_state = PLAYER_STATE.IDLE
	else:
		pass
	
	var target_blend = Vector2(input_dir_x, input_dir_y)
	var new_blend = current_blend.lerp(target_blend, 5.0 * delta)
	$male_casual/AnimationTree.set("parameters/MAIN/blend_position", new_blend)
	
	set_collision_player(player_state)
	move_and_slide()
	get_last_slide_collision()

func _play_footstep_audio():
	var sec
	
	if  moving_flag == true:
		if speed == WALK_SPEED:
			footstep_audio.stream = load("res://sounds/footsteps_3.mp3")
			sec = 3.3
		elif speed == SPRINT_SPEED:
			footstep_audio.stream = load("res://sounds/footsteps_3_running.mp3")
			sec = 1.4
		footstep_audio.play(sec)
	else:
		footstep_audio.stop()

func _on_chair_interacted(body: Variant) -> void:
	var chair_node = get_node(GlobalVar.interactive_node_path)
	var Chair_position = chair_node.global_position
	interacted_obj_rotation_deg = chair_node.global_rotation_degrees
	
	if player_state != PLAYER_STATE.SITTING:
		last_player_position = global_position
		$male_casual/AnimationPlayer.play("sit")
		player_state = PLAYER_STATE.SITTING
		global_position.x = Chair_position.x
		global_position.y = Chair_position.y - 1
		global_position.z = Chair_position.z
		global_rotation_degrees = interacted_obj_rotation_deg

func set_collision_player(state: int):
	match state:
		PLAYER_STATE.IDLE, PLAYER_STATE.WALKING, PLAYER_STATE.SPRINTING:
			for i in range(1,5):
				$".".set_collision_mask_value(i,true)
		PLAYER_STATE.SITTING:
			$".".set_collision_mask_value(1,false)
