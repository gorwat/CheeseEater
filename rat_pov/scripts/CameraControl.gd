extends Camera3D

@export var follow_target: Node3D  # The object the camera should follow (the player)
@export var follow_speed: float = 15.0  # Follow/Mouse speed
@export var rotation_speed_deg: float = 90.0  # Rotation speed (deg/sec)
@export var camera_offset: Vector3 = Vector3(0, 3, -5)  # cam offset

var current_rotation_angle: float = 0.0  # Tracker

func _ready():
	if follow_target:
		# Initialize camera position
		var offset_rotated = camera_offset.rotated(Vector3.UP, current_rotation_angle)
		global_position = follow_target.global_position + offset_rotated
	else:
		print("Error: 'follow_target' is not assigned.")

func _process(delta: float) -> void:
	if follow_target:
		# Rotate the camera when left or right movement is detected
		var rotation_delta = 0.0
		if Input.is_action_pressed("move_left"):
			rotation_delta += deg_to_rad(rotation_speed_deg) * delta
		if Input.is_action_pressed("move_right"):
			rotation_delta -= deg_to_rad(rotation_speed_deg) * delta

		# Accumulate the rotation angle
		current_rotation_angle += rotation_delta

		# Calculate the new position by applying the rotation around the follow target (the player)
		var offset_rotated = camera_offset.rotated(Vector3.UP, current_rotation_angle)
		var target_position = follow_target.global_position + offset_rotated

		# Directly set the camera's position to the target
		global_position = target_position

		# Keep the camera looking at the player
		look_at(follow_target.global_position, Vector3.UP)

		# Rotate the player to face the same direction as the camera
		follow_target.rotation.y = current_rotation_angle + PI
	else:
		print("Error: 'follow_target' is not assigned.")
