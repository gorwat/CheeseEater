extends SpotLight3D

signal spot_position_changed

var stdio_pipe
var thread

# Called when the node enters the scene tree for the first time.
func _ready():
	# setup connection to stdio to executable
	var file_path = "res://table_communication/dummy_coordinates.app" 
	var table_pipe = OS.execute_with_pipe(file_path, [])
	stdio_pipe = table_pipe["stdio"]
	
	# check if file exists
	if FileAccess.file_exists(file_path):
		print("File exists at path: ", file_path)
	else:
		print("File does not exist at path: ", file_path)
	
	# setup thread
	thread = Thread.new()
	thread.start(_thread_func)
	get_window().close_requested.connect(clean_func)
	
func _thread_func():
	print ("Is open: ", stdio_pipe.is_open())
	while stdio_pipe.is_open() and stdio_pipe.get_error() == OK:
		print("Msg: ", stdio_pipe.get_as_text())
	print("Error: ", stdio_pipe.get_error())

func clean_func():
	stdio_pipe.close()
	thread.wait_to_finish()

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

	
	
