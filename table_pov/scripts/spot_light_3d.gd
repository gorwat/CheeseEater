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
	var hwnd = DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE)
	var dict = OS.execute_with_pipe("./table.exe", [str(hwnd)])
	assert(!dict.is_empty())
	var stdio_pipe = dict["stdio"]
	var pid = dict["pid"]
	while stdio_pipe.is_open() and stdio_pipe.get_error() == OK and !should_close:
		var is_on = stdio_pipe.get_8()
		if is_on == 1:
			var x_scale = stdio_pipe.get_float()
			var y_scale = stdio_pipe.get_float()
			call_deferred("change_spot_position", true, Vector2(x_scale, y_scale))
		else:
			call_deferred("change_spot_position", false, Vector2(0, 0))
	print("Error: ", stdio_pipe.get_error())
	stdio_pipe.close()
	OS.kill(pid)

func clean_func():
	should_close = true
	thread.wait_to_finish()

func change_spot_position(is_on: bool, new_pos_scale: Vector2) -> void:
	if is_on:
		self.visible = true
		self.position.x = 48*(new_pos_scale.x - 0.5)
		self.position.z = 27*(new_pos_scale.y - 0.5)
		spot_position_changed.emit(is_on, self.position)
	else:
		if self.visible:
			self.visible = false
			spot_position_changed.emit(is_on, self.position)
		else:
			pass
