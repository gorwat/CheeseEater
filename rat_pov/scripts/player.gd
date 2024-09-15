extends CharacterBody3D

@export var speed = 5.0
@export var jump_velocity = 4.5
@export var turn_speed = 5.0  # Speed at which the character rotates to face the new direction

signal rat_moved

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Updates when moving the character
var target_velocity = Vector3.ZERO

func _physics_process(delta):
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		target_velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		
		# Get the desired forward direction
		var target_rotation = $Pivot.global_transform.basis.looking_at(direction, Vector3.UP)
		
		# Smoothly rotate towards the target direction using spherical interpolation (slerp)
		$Pivot.global_transform.basis = $Pivot.global_transform.basis.slerp(target_rotation, turn_speed * delta)

	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	# Vertical Velocity
	if not is_on_floor(): 
		target_velocity.y = target_velocity.y - (gravity * delta)
	
	velocity = target_velocity
	move_and_slide()

	if velocity.length_squared() > 0:
		rat_moved.emit(self.position, $Pivot.rotation)
