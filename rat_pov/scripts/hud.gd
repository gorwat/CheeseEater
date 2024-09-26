extends Control

@onready var cheese_counter: Label = $CheeseCounter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_cheese_manager_update_cheeses_eaten(cheeses: int) -> void:
	cheese_counter.text = "%s" % cheeses
	pass # Replace with function body.
