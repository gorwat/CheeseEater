extends Control

@onready var cheese_counter: Label = $CheeseCounter
@onready var rat_caught_screen: Control = $RatCaughtScreen
@onready var timer_out_screen: Control = $TimerOutScreen

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_cheese_manager_update_cheeses_eaten(cheeses: int) -> void:
	cheese_counter.text = "%s" % cheeses
	pass # Replace with function body.

func _on_network_manager_rat_was_caught() -> void:
	rat_caught_screen.visible = true
	
	
	
	
func _on_game_info_game_started() -> void:
	rat_caught_screen.visible = false
	timer_out_screen.visible = false



	
	
# control game from table functions:
func _on_network_manager_timer_out() -> void:
	timer_out_screen.visible = true

func _on_network_manager_game_started() -> void:
	rat_caught_screen.visible = false
	timer_out_screen.visible = false
