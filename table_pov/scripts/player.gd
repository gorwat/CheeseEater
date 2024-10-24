extends CharacterBody3D

signal rat_moved(position: Vector3, rotation: Vector3)

func _physics_process(delta):
	pass


func _on_network_manager_rat_pos_recieved(position : Vector3, rotation : Vector3):
	self.position = position
	self.rotation = rotation
	rat_moved.emit(self.position, self.rotation)
