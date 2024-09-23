extends SpotLight3D

@onready var humming_sound: AudioStreamPlayer3D = $SpotlightHumming
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_network_manager_spot_position_changed(is_on: bool, position : Vector3):
	self.position = position
	self.visible = is_on
	humming_sound.playing = is_on
	
	#print("Visible: ", is_on)
	#print(position)
