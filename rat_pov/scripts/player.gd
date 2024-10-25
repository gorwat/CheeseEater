extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var jump_velocity: float = 4.5
@export var camera_node: Camera3D  # Assign the Camera3D node in the editor

@onready var step_sound: AudioStreamPlayer = $RatTippyTaps
@onready var animation_player: AnimationPlayer = $Sketchfab_Scene/AnimationPlayer

var rat_caught = false

signal rat_moved(position: Vector3, rotation: Vector3)

func _ready() -> void:
	animation_player.movie_quit_on_finish = true

func _process(delta: float) -> void:
	# Play footstep sounds only when the rat is moving and on the ground
	if is_on_floor() and velocity.length_squared() > 0.0:
		if not step_sound.playing:
			step_sound.play()
	else:
		step_sound.playing = false
		

func _physics_process(delta: float) -> void:
	# Handle gravity and jumping
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0  # Reset vertical velocity when on the ground

	# Handle movement input
	var movement_input = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		movement_input.y += 1
	if Input.is_action_pressed("move_back"):
		movement_input.y -= 1
	if Input.is_action_pressed("move_left"):
		movement_input.x -= 1
	if Input.is_action_pressed("move_right"):
		movement_input.x += 1

	movement_input = movement_input.normalized()

	if camera_node:
		# Convert 2D movement input to 3D
		var direction = Vector3(movement_input.x, 0, movement_input.y)

		# Rotate the direction based on the camera's orientation
		var camera_transform = camera_node.global_transform
		var forward = -camera_transform.basis.z.normalized()
		var right = camera_transform.basis.x.normalized()
		var move_direction = (right * direction.x + forward * direction.z).normalized() * speed

		# Apply movement
		velocity.x = move_direction.x
		velocity.z = move_direction.z

		# Rotate player to face movement direction if moving
		if movement_input != Vector2.ZERO:
			var target_rotation = atan2(-move_direction.x, -move_direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, 0.1)
	else:
		print("Error: 'camera_node' is not assigned.")

	move_and_slide()

	# Emit signal if moving
	if velocity.length_squared() > 0.0:
		rat_moved.emit(self.position, self.rotation)
		if not animation_player.current_animation == "Armature|Walk":
			animation_player.speed_scale = 3
			animation_player.play("Armature|Walk")
	else:
		if not animation_player.current_animation == "Armature|Idle":
			animation_player.speed_scale = 1.0
			animation_player.play("Armature|Idle")

func _on_network_manager_rat_was_caught() -> void:
	rat_caught = true

func _on_game_info_game_started(session_duration: int) -> void:
	rat_caught = false
	position = Vector3(0, -0.285, 0)
	rotation = Vector3(0, 0, 0)
