extends Node3D

@export var follow_target: CharacterBody3D
@export var rotation_speed_deg: float = 180.0  # Rotation speed in degrees per second
@export var camera_offset: Vector3 = Vector3(0, 1, 2)  # Camera offset from the player
@export var rotation_smoothing: float = 0.2  # Adjust for smoother rotation (0 = instant, higher = smoother)
@export var smoothing_speed: float = 15.0  # Higher value smoothens but introduces delay
@export var min_camera_distance: float = 1.5
@export var recenter_speed: float = 3.0  # Recentering aggressiveness
@export var recenter_enable: bool = true  # Enable automatic recentering

var max_camera_distance: float  # Maximum camera distance, set based on camera_offset.z
var target_rotation_angle: float = 0.0
var current_rotation_angle: float = 0.0

var desired_spring_length: float
var current_spring_length: float

var rotation_input_time: float = 0.0
var backward_movement_time: float = 0.0  # Backwards movement timer (s key)

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera_node: Camera3D = $SpringArm3D/Camera3D
@onready var probe_node: ShapeCast3D = $SpringArm3D/Probe

func _ready():
	if not follow_target:
		print("Error: 'follow_target' is not assigned.")
		return

	# Configure maximum camera distance based on camera_offset.z
	max_camera_distance = abs(camera_offset.z)

	# Set initial position and rotation
	global_position = follow_target.global_position
	target_rotation_angle = 0.0
	current_rotation_angle = 0.0

	# Configure spring arm
	desired_spring_length = max_camera_distance
	current_spring_length = desired_spring_length
	spring_arm.spring_length = current_spring_length
	spring_arm.position = Vector3(0, camera_offset.y, 0)
	camera_node.position = Vector3.ZERO  # Ensure camera is at the end of the spring arm
	camera_node.rotation_degrees.x = -25

	# Configure probe node for collision detection
	if probe_node:
		probe_node.enabled = true
		# Assign a sphere shape if not already assigned
		if probe_node.shape == null:
			probe_node.shape = SphereShape3D.new()
			(probe_node.shape as SphereShape3D).radius = 0.3  # Adjust as needed
		probe_node.collision_mask = 1  # Adjust to match collision layers
		probe_node.target_position = Vector3(0, 0, -max_camera_distance)
	else:
		print("Error: 'Probe' node not found under 'SpringArm3D'.")

	# Connect to signals from GameInfo (if applicable)
	var game_info = get_node("../GameInfo")
	if game_info.has_method("recenter_speed_changed"):
		game_info.recenter_speed_changed.connect(_on_recenter_speed_changed)
	if game_info.has_method("rotation_speed_changed"):
		game_info.rotation_speed_changed.connect(_on_rotation_speed_changed)

func _process(delta: float) -> void:
	if not follow_target:
		return

	if rotation_input_time > 0.0:
		rotation_input_time -= delta

	# Handle camera rotation input
	var rotation_delta = 0.0
	if Input.is_action_pressed("camera_left"):
		rotation_delta += deg_to_rad(rotation_speed_deg) * delta
		rotation_input_time = 0.5
	if Input.is_action_pressed("camera_right"):
		rotation_delta -= deg_to_rad(rotation_speed_deg) * delta
		rotation_input_time = 0.5

	target_rotation_angle += rotation_delta

	var moving_backward = Input.is_action_pressed("move_back")

	if moving_backward:
		backward_movement_time += delta
	else:
		backward_movement_time = 0.0

	# Recenter logic
	if rotation_input_time <= 0.0 and recenter_enable:
		if moving_backward and backward_movement_time < 2.0:
			# Do not recenter when moving backward for less than 2 seconds
			pass
		else:
			# Recenter when not moving backward or after 2 seconds of backward movement
			var player_rotation_y = follow_target.rotation.y
			var recenter_smoothing = delta * recenter_speed
			target_rotation_angle = lerp_angle(target_rotation_angle, player_rotation_y, recenter_smoothing)

	current_rotation_angle = lerp_angle(current_rotation_angle, target_rotation_angle, rotation_smoothing)

	spring_arm.rotation.y = current_rotation_angle
	global_position = follow_target.global_position
	probe_node.force_shapecast_update()

	# Check for collisions using the probe
	if probe_node.get_collision_count() > 0:
		# Get the collision point of the first collision
		var collision_point = probe_node.get_collision_point(0)
		var collision_distance = collision_point.distance_to(spring_arm.global_transform.origin)
		# Increase the buffer to prevent sudden jumps
		var collision_buffer = 0.5  # Change via interface if needed
		desired_spring_length = clamp(collision_distance - collision_buffer, min_camera_distance, max_camera_distance)
	else:
		desired_spring_length = max_camera_distance

	# Anti-jagging / wall phasing
	var max_change = 1.0 * delta  # Maximum change per frame
	desired_spring_length = clamp(
		desired_spring_length,
		current_spring_length - max_change,
		current_spring_length + max_change
	)

	# Smooth interpolation for camera
	current_spring_length = lerp(current_spring_length, desired_spring_length, smoothing_speed * delta)
	spring_arm.spring_length = current_spring_length

func _on_game_info_game_started(session_duration: int) -> void:
	current_rotation_angle = 0.0
	target_rotation_angle = 0.0
	spring_arm.rotation.y = 0.0
	probe_node.force_shapecast_update()

func _on_recenter_speed_changed(new_speed: float) -> void:
	recenter_speed = new_speed

func _on_rotation_speed_changed(new_speed: float) -> void:
	rotation_speed_deg = new_speed
