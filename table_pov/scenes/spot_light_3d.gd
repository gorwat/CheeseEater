extends SpotLight3D

signal spot_position_changed

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#var mouse_position = get_viewport().get_mouse_position()
	#if (self.position.x != mouse_position.x) || (self.position.z != mouse_position.y):
		#self.position = Vector3(mouse_position.x, self.position.y, mouse_position.y)
		#spot_position_changed.emit(self.position)	
	
	if Input.is_key_pressed(KEY_W):
		self.position.x += 0.1
	if Input.is_key_pressed(KEY_S):
		self.position.x -= 0.1
	if Input.is_key_pressed(KEY_A):
		self.position.z -= 0.1
	if Input.is_key_pressed(KEY_D):
		self.position.z += 0.1
	
	spot_position_changed.emit(self.position)
	
