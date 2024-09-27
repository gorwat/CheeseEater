extends Label

@onready var game_timer: Timer = $Timer
const DEFAULT_TIME = 1*60 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_timer.wait_time = DEFAULT_TIME

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.text = "%d" % game_timer.time_left

func _on_timeout() -> void:
	pass
