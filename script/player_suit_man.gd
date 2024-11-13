extends CharacterBody3D

# WORKING
const WORK_PROGRESS_SHOW_TIME = 5
const EASY_WORK = 1.0
const MED_WORK = 5.0
const HARD_WORK = 10.0
const WTH_WORK = 20.0
const FATIGUE_DRAIN_VAL = 2

# MOVEMENT
const JUMP_VELOCITY = 4.5
const WALK_SPEED = 3.0
const SPRINT_SPEED = 7.0
const SPRINT_STAMINA_DRAIN_VAL = 25
#const JUMP_STAMINA_DRAIN_VAL = 20
const STAMINA_RECOVERY_VAL = 20

# PLAYER STATUS - what is player feeling
enum PLAYER_STATUS {
	NORMAL,
	HUNGRY,
	FULL,
	DIZZY,
	SLEEPY,
	EXHAUSTED,
	SCARED
}

# PLAYER STATE - what is player doing
enum PLAYER_STATE {
	IDLE,
	SITTING,
	WALKING,
	SPRINTING,
	HIDING
}

@onready var foot_step_sound = $foot_step_audio
@onready var mouth_sound = $Head/mouth_sound
@onready var stamina_gauge = get_node("/root/" + get_tree().current_scene.name + "/UI/stamina_gauge")
@onready var work_progress_node = get_node("/root/" + get_tree().current_scene.name + "/UI/work_progress")
@onready var work_progress_label = get_node("/root/" + get_tree().current_scene.name + "/UI/work_progress/label")
@onready var fatigue_gauge = get_node("/root/" + get_tree().current_scene.name + "/UI/fatigue_gauge")
@onready var pc_interact_sound = get_node("/root/" + get_tree().current_scene.name + "/interacts/PC/AudioStreamPlayer3D")
# Time variable
var time_accumulator = 0.0  # Accumulates delta each frame
var seconds_count = 0
var minutes_count = 0
var hours_count = 0
var second_flag = false
var minute_flag = false
var hour_flag = false

# movement
var speed
var moving_flag: bool = false
var walking_sound_flag: bool = false
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# player state and position
var cur_player_state
var pre_player_state
var last_player_position: Vector3
var interacted_obj_rotation_deg: Vector3

# working / mission
var work_progress = 0.0
var work_complete = 0.0
var work_update_flag = false
var work_time_count = 0
var work_difficulty = 0

# player status
var player_status : Array = [0,0,0]

func _ready():
	Input.mouse_mode =Input.MOUSE_MODE_CAPTURED
	GlobalVar.pause_status = false
	speed = WALK_SPEED
	$AnimationTree.set("parameters/MAIN/blend_position",Vector2(0,0))
	last_player_position = global_position
	cur_player_state = PLAYER_STATE.IDLE
	pre_player_state = PLAYER_STATE.IDLE
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Create and assign a PhysicsMaterial to reduce friction
#	var material = PhysicsMaterial.new()
#	material.friction = 0.1  # Lower friction to prevent sticking
#	material.bounce = 0.0    # Optional: Set bounce if needed
#	$CollisionShape3D.material_override = material

# Camera Control
func _input(event: InputEvent) -> void:
	var min_deg
	var max_deg
	if event is InputEventMouseMotion and !GlobalVar.pause_status:
		match cur_player_state:
			PLAYER_STATE.SITTING:
				$".".rotate_y(-event.relative.x * 0.005)
				$Head.rotate_x(-event.relative.y * 0.005)
				$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-70),deg_to_rad(90))
				$".".rotation.y = clamp($".".rotation.y, deg_to_rad(interacted_obj_rotation_deg.y - 50) \
				,deg_to_rad(interacted_obj_rotation_deg.y + 50))
				
			PLAYER_STATE.HIDING:
				pass
			_:
				$".".rotate_y(-event.relative.x * 0.005)
				$Head.rotate_x(-event.relative.y * 0.005)
				$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-90),deg_to_rad(90))
	else:
		pass
	
	if GlobalVar.pause_status:
		Input.mouse_mode =Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode =Input.MOUSE_MODE_CAPTURED
		

func _process(delta):
	delta_to_second(delta)
	
	# Stamina Show
	if stamina_gauge.value < (stamina_gauge.max_value):
		stamina_gauge.visible = true
	else:
		stamina_gauge.visible = false

	# Handle Stamina.
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

	# Work Progress
	if work_update_flag:
		work_update_flag = false
		work_progress_node.visible = true
		if work_complete >= 100:
			work_complete = 100
			work_progress_label.text = "PROGRESS " + \
			str(GlobalVar.round_to_dec(work_complete,2)) + "% (DONE)"
		else:
			work_progress_label.text = "PROGRESS " + \
			str(GlobalVar.round_to_dec(work_complete,2)) + "%"
		work_time_count = 0
	elif work_progress_node.visible == true and work_time_count > WORK_PROGRESS_SHOW_TIME:
		work_progress_node.visible = false
	else:
		pass
		
	if Input.is_action_just_pressed("flashlight"):
		if $Head/flashlight.visible == false:
			$Head/flashlight.visible = true
		else:
			$Head/flashlight.visible = false

	if second_flag:
		second_flag = false
		if work_progress_node.visible: # work progress showing countdown
			work_time_count += 1

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
	
	#if input_dir.x == 0 and input_dir.y == 0:
		#foot_step_sound.stop()
		
	if Input.is_action_just_pressed("sprint") and is_on_floor() and \
	stamina_gauge.value > (stamina_gauge.min_value + 30):
		speed = SPRINT_SPEED
	elif Input.is_action_just_released("sprint") and is_on_floor():
		speed = WALK_SPEED
	else:
		pass

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		moving_flag = true
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		moving_flag = false
		
	# Smoothly transition the animation blend position
	var current_blend = $AnimationTree.get("parameters/MAIN/blend_position")
	var input_dir_x = input_dir.x
	var input_dir_y = -input_dir.y
	if speed == WALK_SPEED and moving_flag == true:
		input_dir_y = input_dir_y * 0.66
		pre_player_state = cur_player_state
		cur_player_state = PLAYER_STATE.WALKING
	elif speed == SPRINT_SPEED and moving_flag == true:
		input_dir_y = input_dir_y
		pre_player_state = cur_player_state
		cur_player_state = PLAYER_STATE.SPRINTING
	elif moving_flag == false and \
	$AnimationPlayer.current_animation != "sit" and \
	cur_player_state != PLAYER_STATE.HIDING:
		pre_player_state = cur_player_state
		cur_player_state = PLAYER_STATE.IDLE
	else:
		pass
	
	var target_blend = Vector2(input_dir_x, input_dir_y)
	var new_blend = current_blend.lerp(target_blend, 5.0 * delta)
	$AnimationTree.set("parameters/MAIN/blend_position", new_blend)
	
	if pre_player_state == PLAYER_STATE.SITTING or \
	pre_player_state == PLAYER_STATE.HIDING:
		$AnimationPlayer.stop()
		global_position = last_player_position
		
	if pre_player_state != cur_player_state:
		set_collision_player(cur_player_state)
	move_and_slide()
	get_last_slide_collision()

func play_foot_step_sound():
	if  moving_flag == true:
		if speed == WALK_SPEED:
			foot_step_sound.stream = load("res://sounds/footsteps_2.mp3")
		elif speed == SPRINT_SPEED:
			foot_step_sound.stream = load("res://sounds/footsteps_2_running.mp3")
		foot_step_sound.play()

func set_collision_player(state: int):
	match state:
		PLAYER_STATE.IDLE, PLAYER_STATE.WALKING, PLAYER_STATE.SPRINTING:
			for i in range(1,5):
				$".".set_collision_mask_value(i,true)
		PLAYER_STATE.SITTING, PLAYER_STATE.HIDING:
			$".".set_collision_mask_value(1,false)

func fatigue_drain() -> void:
	# Drain Fatigue.
	if work_update_flag and fatigue_gauge.value > (fatigue_gauge.min_value + 5):
		fatigue_gauge.value = fatigue_gauge.value - (work_progress * work_difficulty * FATIGUE_DRAIN_VAL)
	else:
		pass
		
func fatigue_recovery() -> void:
	# Recover Fatigue.
	if fatigue_gauge.value < 1000:
		fatigue_gauge.value += 200
		if fatigue_gauge.value >= 1000:
			fatigue_gauge.value = 1000
	else:
		pass

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

func _on_chair_interacted(body: Variant) -> void:
	var chair_node = get_node(GlobalVar.interactive_node_path)
	var chair_position = chair_node.global_position
	interacted_obj_rotation_deg = chair_node.global_rotation_degrees
	
	if cur_player_state != PLAYER_STATE.SITTING:
		last_player_position = global_position
		$AnimationPlayer.play("sit")
		pre_player_state = cur_player_state
		cur_player_state = PLAYER_STATE.SITTING
		global_position.x = chair_position.x
		global_position.y = chair_position.y - 1
		global_position.z = chair_position.z
		global_rotation_degrees = interacted_obj_rotation_deg

func _on_locker_interacted(body: Variant) -> void:
	var locker_node = get_node(GlobalVar.interactive_node_path)
	var locker_position = locker_node.global_position
	interacted_obj_rotation_deg = locker_node.global_rotation_degrees
	
	if cur_player_state != PLAYER_STATE.HIDING:
		last_player_position = global_position
		pre_player_state = cur_player_state
		cur_player_state = PLAYER_STATE.HIDING
		global_position.x = locker_position.x
		global_position.z = locker_position.z
		global_rotation_degrees = interacted_obj_rotation_deg
		$Head.rotation.x = 0

func _on_pc_interacted(body: Variant) -> void:
	work_difficulty = EASY_WORK
	work_progress = (randf_range(0.1, 2)/work_difficulty)
	work_update_flag = true
	if work_complete >= 100:
		pass
	else:
		work_complete += work_progress
		fatigue_drain()
	if pc_interact_sound.playing == false and pc_interact_sound.stream_paused == false:
		pc_interact_sound.play()
	elif pc_interact_sound.stream_paused:
		pc_interact_sound.stream_paused = false
		
func _on_food_interacted(body: Variant) -> void:
	fatigue_recovery()
	mouth_sound.stream = load("res://sounds/eating-sound-effect.mp3")
	mouth_sound.volume_db = -40
	mouth_sound.pitch_scale = 0.8
	mouth_sound.play()
