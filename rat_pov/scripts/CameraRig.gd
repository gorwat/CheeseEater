extends Node3D

@export var follow_target: Node3D  # interface override
@export var rotation_speed_deg: float = 180.0  # Rotation speed in deg/sec
@export var camera_offset: Vector3 = Vector3(0, 1, 2)  # offset
@export var rotation_smoothing: float = 0.2  # Adjust for smoother rotation (0 = instant, higher = smoother)
@export var smoothing_speed: float = 15.0  # higher value will smoothen but introduce delay
@export var min_camera_distance: float = 1.5

var max_camera_distance: float  # Maximum camera distance, set based on camera_offset.z
var target_rotation_angle: float = 0.0
var current_rotation_angle: float = 0.0

var desired_spring_length: float
var current_spring_length: float

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
		probe_node.collision_mask = 1  # Adjust to match your collision layers
		probe_node.target_position = Vector3(0, 0, -max_camera_distance)
	else:
		print("Error: 'Probe' node not found under 'SpringArm3D'.")

func _process(delta: float) -> void:
	if not follow_target:
		return

	# Handle camera rotation input
	var rotation_delta = 0.0
	if Input.is_action_pressed("camera_left"):
		rotation_delta += deg_to_rad(rotation_speed_deg) * delta
	if Input.is_action_pressed("camera_right"):
		rotation_delta -= deg_to_rad(rotation_speed_deg) * delta

	target_rotation_angle += rotation_delta
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
		var collision_buffer = 0.5  # change via interface if needed
		desired_spring_length = clamp(collision_distance - collision_buffer, min_camera_distance, max_camera_distance)
	else:
		desired_spring_length = max_camera_distance

	# anti-jagging / wall phasing
	var max_change = 1.0 * delta  # Maximum change per frame
	desired_spring_length = clamp(
		desired_spring_length,
		current_spring_length - max_change,
		current_spring_length + max_change
	)

	# smooth interpolation / cam
	current_spring_length = lerp(current_spring_length, desired_spring_length, smoothing_speed * delta)
	spring_arm.spring_length = current_spring_length

func _on_game_info_game_started(session_duration : int) -> void:
	current_rotation_angle = 0.0
	target_rotation_angle = 0.0
	spring_arm.rotation.y = 0.0
	probe_node.force_shapecast_update()
