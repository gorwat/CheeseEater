extends SpotLight3D

signal spot_position_changed

var stdio_pipe
var thread

# Called when the node enters the scene tree for the first time.
func _ready():
	# assign and check file path
	var file_path = "res://table_communication/dummy_coordinates" 
	if FileAccess.file_exists(file_path):
		print("File exists at path: ", file_path)
	else:
		print("File does not exist at path: ", file_path)
		
	# setup connection to executable
	var dict = OS.execute_with_pipe(file_path, [])
	
	if !dict.is_empty():
		stdio_pipe = dict["stdio"]
		
		thread = Thread.new()
		thread.start(_thread_func)
		get_window().close_requested.connect(clean_func)
		
	else:
		print("Connection failed; execute_with_pipeline returned: ", dict)
		
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
	if Input.is_key_pressed(KEY_W):
		self.position.z += 0.1
	if Input.is_key_pressed(KEY_S):
		self.position.z -= 0.1
	if Input.is_key_pressed(KEY_A):
		self.position.x += 0.1
	if Input.is_key_pressed(KEY_D):
		self.position.x -= 0.1
	
	spot_position_changed.emit(self.position)

	
	
