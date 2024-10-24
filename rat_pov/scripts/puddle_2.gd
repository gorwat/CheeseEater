extends Node3D
@onready var area = $Area3D 
@onready var puddle = $Puddle
@onready var puddle_material = puddle.get_active_material(0) as ShaderMaterial

var rat: CharacterBody3D = null
const TIME_BETWEEN_RIPPLES = 0.5
const RIPPLE_DECREASE_SPEED = 0.1
const MAX_RIPPLES = 10 
var time_since_last_ripple = TIME_BETWEEN_RIPPLES

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exit)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# If rat is inside puddle
	if rat != null:
		if time_since_last_ripple >= TIME_BETWEEN_RIPPLES:
			if rat.velocity.length_squared() > 0.0:
				create_ripple(rat.position)
				time_since_last_ripple = 0
		time_since_last_ripple += delta
	update_ripples(delta)
		
func create_ripple(rat_pos: Vector3):
	var ripple_position = puddle.to_local(rat_pos) as Vector3
	
	var ripple_count = puddle_material.get_shader_parameter("wave_sources_size")
	var ripples = puddle_material.get_shader_parameter("wave_sources") as PackedVector2Array
	var ripple_amplitudes =  puddle_material.get_shader_parameter("wave_amplitudes") as PackedFloat32Array
	if ripples.size() == 10:
		pass
	else:
		ripples.append(Vector2(ripple_position.x, ripple_position.z));
		ripple_amplitudes.append(1.0);
		ripple_count += 1;
		puddle_material.set_shader_parameter("wave_sources_size", ripple_count)
		puddle_material.set_shader_parameter("wave_sources", ripples) 
		puddle_material.set_shader_parameter("wave_amplitudes", ripple_amplitudes)

func update_ripples(delta: float):
	var ripple_count = puddle_material.get_shader_parameter("wave_sources_size")
	var ripples = puddle_material.get_shader_parameter("wave_sources") as PackedVector2Array
	var ripple_amplitudes =  puddle_material.get_shader_parameter("wave_amplitudes") as PackedFloat32Array
	# Iterate backwards through ripples
	for i in range(ripple_count-1, -1, -1):
		ripple_amplitudes[i] -= RIPPLE_DECREASE_SPEED*delta
		if ripple_amplitudes[i] <= 0.0:
			ripple_count -= 1
			ripples.remove_at(i)
			ripple_amplitudes.remove_at(i)
			
	puddle_material.set_shader_parameter("wave_sources_size", ripple_count)
	puddle_material.set_shader_parameter("wave_sources", ripples) 
	puddle_material.set_shader_parameter("wave_amplitudes", ripple_amplitudes)

func _on_area_body_entered(body: Node3D) -> void:
	rat = body
	pass
func _on_area_body_exit(body: Node3D) -> void:
	rat = null
	pass
