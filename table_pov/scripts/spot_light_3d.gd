extends SpotLight3D

signal spot_position_changed
const PORT = 1337
const ADDRESS = "127.0.0.1"
var thread
var should_close: bool = false
var socket
var exec_dict

func _ready():
	exec_dict = OS.execute_with_pipe("table.exe",[])
	socket = PacketPeerUDP.new()
	socket.bind(PORT, ADDRESS)
	print("Listening on localhost ", PORT)
	
func _exit_tree() -> void:
	OS.kill(exec_dict["pid"])
	
func _process(delta: float) -> void:
	var packets = socket.get_available_packet_count()
	if packets > 0:
		var last_packet
		for i in range(packets):
			var packet = socket.get_packet()
			if i == packets - 1:
				last_packet = packet
		
		var is_on = last_packet.decode_u8(0)
		if is_on == 1:
			var x_scale = last_packet.decode_float(1)
			var y_scale = last_packet.decode_float(5)
			change_spot_position( true, Vector2(x_scale, y_scale))
		else:
			change_spot_position( false, Vector2(0, 0))
	else:
		pass
		
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
