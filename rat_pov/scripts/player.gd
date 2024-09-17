extends CharacterBody3D

@export var speed = 2.0
@export var jump_velocity = 4.5
@export var turn_speed = 1.0  # Speed of rotating the environment
@export var gravity = 2000.0  # enabled for now to prevent flying bug (to fix)

signal rat_moved

var target_velocity = Vector3.ZERO
var current_rotation_angle = 0.0  # Keeps track of how much the environment has turned

func _physics_process(delta: float):
	# Reset movement speed each frame
	target_velocity = Vector3.ZERO

	# Jump if on the ground
	if Input.is_action_just_pressed("jump") and is_on_floor():
		target_velocity.y = jump_velocity

	# Handle forward/backward movement
	var forward_input = 0.0

	if Input.is_action_pressed("move_back"):
		forward_input -= 1
	if Input.is_action_pressed("move_forward"):
		forward_input += 1
	
	# Move based on input direction
	if forward_input != 0:
		var forward = -get_node("/root/Main/Camera3D").global_transform.basis.z
		target_velocity.x = forward.x * speed * forward_input
		target_velocity.z = forward.z * speed * forward_input

	# Rotate the environment left or right
	var rotation_delta = 0.0
	if Input.is_action_pressed("move_left"):
		rotation_delta -= turn_speed * delta
	elif Input.is_action_pressed("move_right"):
		rotation_delta += turn_speed * delta

	# Update the total rotation of the environment
	current_rotation_angle += rotation_delta

	# Apply the rotation to the environment
	get_node("/root/Main/Ground/MeshInstance3D").rotation.y = current_rotation_angle

	# Apply gravity to prevent flying
	if not is_on_floor():
		target_velocity.y -= gravity * delta

	# Move the character
	velocity = target_velocity
	move_and_slide()

	# Emit signal when the character moves
	if velocity.length_squared() > 0:
		rat_moved.emit(self.position, $Pivot.rotation)
