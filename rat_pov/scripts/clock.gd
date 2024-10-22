extends Label

@onready var game_timer: Timer = $Timer
const DEFAULT_TIME = 1*10 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_timer.wait_time = DEFAULT_TIME

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.text = seconds2mmss(game_timer.time_left)#"%d" % game_timer.time_left


func seconds2mmss(total_seconds: float) -> String:
	#total_seconds = 12345
	var seconds:float = fmod(total_seconds , 60.0)
	var minutes:int   =  int(total_seconds / 60.0) % 60
	var hhmmss_string:String = "%02d:%02d" % [minutes, seconds]
	return hhmmss_string
	
	
func _on_timeout() -> void:
	pass
