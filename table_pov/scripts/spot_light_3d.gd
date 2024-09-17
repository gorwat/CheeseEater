extends SpotLight3D

signal spot_position_changed
const PORT = 1337
var thread
var should_close: bool = false

func _ready():
	# setup connection to executable
	thread = Thread.new()
	thread.start(_thread_func)
	get_window().close_requested.connect(clean_func)

func _thread_func():
	var dict = OS.execute_with_pipe("table.exe",[])
	var server = UDPServer.new()
	server.listen(PORT)
	print("Listening on localhost ", PORT)
	while true:
		server.poll() # Important!
		if server.is_connection_available():
			var peer: PacketPeerUDP = server.take_connection()
			var packets = peer.get_available_packet_count()
			for p in range(packets):
				var packet = peer.get_packet()
				var is_on = packet.decode_u8(0)
				if is_on == 1:
					var x_scale = packet.decode_float(1)
					var y_scale = packet.decode_float(5)
					call_deferred("change_spot_position", true, Vector2(x_scale, y_scale))
				else:
					call_deferred("change_spot_position", false, Vector2(0, 0))
	OS.kill(dict["pid"])

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
