extends Node3D

@export var follow_target: Node3D  # Assign the player node in the editor
@export var rotation_speed_deg: float = 90.0  # Rotation speed (degrees per second)
@export var camera_offset: Vector3 = Vector3(0, 3, -5)  # Camera offset

var current_rotation_angle: float = 0.0  # Tracker

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera_node: Camera3D = $SpringArm3D/Camera3D

func _ready():
	if follow_target:
		# Initialize camera position
		current_rotation_angle = 0.0
		rotation.y = current_rotation_angle

		# Set the spring arm length and position
		spring_arm.spring_length = abs(camera_offset.z)
		spring_arm.position = Vector3(0, camera_offset.y, 0)
		camera_node.position = Vector3.ZERO
	else:
		print("Error: 'follow_target' is not assigned.")

func _process(delta: float) -> void:
	if follow_target:
		# Handle camera rotation input
		var rotation_delta = 0.0
		if Input.is_action_pressed("camera_left"):
			rotation_delta += deg_to_rad(rotation_speed_deg) * delta
		if Input.is_action_pressed("camera_right"):
			rotation_delta -= deg_to_rad(rotation_speed_deg) * delta

		# Accumulate the rotation angle
		current_rotation_angle += rotation_delta

		# Update the rotation of the CameraRig
		rotation.y = current_rotation_angle

		# Position the CameraRig at the player's position
		global_position = follow_target.global_position
	else:
		print("Error: 'follow_target' is not assigned.")
