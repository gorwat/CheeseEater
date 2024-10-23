extends Control

@onready var countdown_timer: Timer = $Timer
@onready var countdown_msg: Label = $Message

var counter_speed = 1
var current_index = 0
var messages = ["Ready?", "Ready?", "Ready?", "3", "2", "1", "Go!"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	countdown_timer.wait_time = counter_speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
		
func start_countdown():
	current_index = 0
	countdown_msg.text = messages[0]
	visible = true
	
	countdown_timer.start()
	
func _on_timeout() -> void:
	current_index += 1
	if (current_index < messages.size()):
		countdown_msg.text = messages[current_index]
	else:
		visible = false
		countdown_timer.stop()
