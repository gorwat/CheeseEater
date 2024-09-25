extends CharacterBody3D

@export var speed: float = 10.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var jump_velocity: float = 4.5
@export var camera_node: Camera3D  # Assign in editor

@onready var step_sound: AudioStreamPlayer = $RatTippyTaps

signal rat_moved(position: Vector3, rotation: Vector3)

func _process(delta: float) -> void:
	if self.velocity.length_squared() > 0:
		if !step_sound.playing:
			step_sound.play()
			
	else:
		step_sound.playing = false

func _physics_process(delta: float) -> void:
	# Handle gravity and jumping (when implemented, idk not using this)
	if not is_on_floor():
		velocity.y -= gravity * delta
	# We will not jump
	#else:
	#	if Input.is_action_just_pressed("jump"):
	#		velocity.y = jump_velocity

	# Handle forward/backward movement
	var forward_input = 0.0
	if Input.is_action_pressed("move_back"):
		forward_input -= 1
	if Input.is_action_pressed("move_forward"):
		forward_input += 1

	var target_velocity = Vector3.ZERO

	if camera_node:
		# Calculate movement direction based on camera
		if forward_input != 0.0:
			var forward_direction = -camera_node.global_transform.basis.z.normalized()
			target_velocity.x = forward_direction.x * speed * forward_input
			target_velocity.z = forward_direction.z * speed * forward_input
	else:
		print("Error: 'camera_node' is missing.")
		return

	# Apply horizontal movement
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z

	move_and_slide()

	# Emit signal if moving
	if velocity.length_squared() > 0.0:
		rat_moved.emit(self.position, self.rotation)
