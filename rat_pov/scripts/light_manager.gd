extends Node

var spot_scene = preload("res://scenes/spot.tscn")

var spot_count: int = 10

func _ready() -> void:
	for n in range(spot_count):
		var spot = spot_scene.instantiate()
		add_child(spot)
		get_child(n).visible = false
		get_child(n).get_child(0).playing = false

func _on_network_manager_spot_positions_changed(positions: PackedVector3Array, angles: PackedFloat32Array):
	if positions.size() > spot_count:
		return
	
	for n in range(spot_count):
		get_child(n).visible = false
		get_child(n).get_child(0).playing = false
	
	for n in range(positions.size()):
		get_child(n).visible = true
		get_child(n).position = positions[n]
		get_child(n).spot_angle = angles[n]
		get_child(n).get_child(0).playing = true
