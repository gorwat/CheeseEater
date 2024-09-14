extends SpotLight3D

signal spot_position_changed

var thread
var should_close: bool = false

func _ready():
	# setup connection to executable
	thread = Thread.new()
	thread.start(_thread_func)
	get_window().close_requested.connect(clean_func)

func _thread_func():
	var dict = OS.execute_with_pipe("table.exe", [])
	assert(!dict.is_empty())
	var stdio_pipe = dict["stdio"]
	var pid = dict["pid"]
	while stdio_pipe.is_open() and stdio_pipe.get_error() == OK and !should_close:
		var x = stdio_pipe.get_float()
		var y = stdio_pipe.get_float()
		var z = stdio_pipe.get_float()
		print(x, y, z)
	print("Error: ", stdio_pipe.get_error())
	stdio_pipe.close()
	OS.kill(pid)

func clean_func():
	should_close = true
	thread.wait_to_finish()

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
