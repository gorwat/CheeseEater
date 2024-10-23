extends Node3D

var material
var material2
var material3
var player

var in_bush = false
var shaking_bush = false
var max_shake_time = 1
var shake_timer = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# unlink plant instance from others by duplicating it 
	$PlantMesh.set_surface_override_material(0, $PlantMesh.get_active_material(0).duplicate());
	$PlantMesh2.set_surface_override_material(0, $PlantMesh2.get_active_material(0).duplicate());
	$PlantMesh3.set_surface_override_material(0, $PlantMesh3.get_active_material(0).duplicate());
	
	# get spatial shader
	material = $PlantMesh.get_active_material(0)
	material2 = $PlantMesh2.get_active_material(0)
	material3 = $PlantMesh3.get_active_material(0)
	
	# need to init false (apparently, but can't really find what makes default true)
	material.set_shader_parameter("shaking_bush", shaking_bush) 
	
	# connect player moved signal
	player = get_node("/root/Main/Player")
	player.rat_moved.connect(_on_rat_moved)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if shaking_bush:
		if (shake_timer < 0):
			shaking_bush = false
			material.set_shader_parameter("shaking_bush", shaking_bush)
			material2.set_shader_parameter("shaking_bush", shaking_bush)
			material3.set_shader_parameter("shaking_bush", shaking_bush)
		else:
			shake_timer = shake_timer - delta
			material.set_shader_parameter("time_left", shake_timer)
			material2.set_shader_parameter("time_left", shake_timer)
			material3.set_shader_parameter("time_left", shake_timer)
	
func _on_rat_moved(position:Vector3, rotation:Vector3):
	if in_bush and !shaking_bush:
		shake_timer = max_shake_time
		shaking_bush = true
		material.set_shader_parameter("shaking_bush", shaking_bush)
		material2.set_shader_parameter("shaking_bush", shaking_bush)
		material3.set_shader_parameter("shaking_bush", shaking_bush)
		material.set_shader_parameter("time_left", shake_timer)
		material2.set_shader_parameter("time_left", shake_timer)
		material3.set_shader_parameter("time_left", shake_timer)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
		in_bush = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == player:
		in_bush = false
