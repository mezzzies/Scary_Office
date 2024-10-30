extends CharacterBody3D

const JUMP_VELOCITY = 4.5
const WALK_SPEED = 3.0
const SPRINT_SPEED = 7.0
const SPRINT_STAMINA_DRAIN_VAL = 25
#const JUMP_STAMINA_DRAIN_VAL = 20
const STAMINA_RECOVERY_VAL = 20

var speed
var stamina_gauge

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	speed = WALK_SPEED
	stamina_gauge = get_node("/root/" + get_tree().current_scene.name + "/UI/stamina_gauge")

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
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	
