extends Camera3D

@export var follow_target: Node3D
@export var follow_speed: float = 5.0
@export var camera_offset: Vector3 = Vector3(0, 3, 5)  # Camera positioned behind and above the target

func _process(delta: float) -> void:
	if follow_target:
		# Calculate where the camera should be, keeping the offset
		var target_position: Vector3 = follow_target.global_transform.origin + camera_offset
		
		# Move the camera smoothly towards the target position
		global_transform.origin = global_transform.origin.lerp(target_position, follow_speed * delta)
