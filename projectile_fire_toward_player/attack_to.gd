extends Node2D

@export var attack_to : Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not attack_to == null: # now it's working..
		$spear.look_at(attack_to.global_position)
	pass


func _on_cool_down_timer_timeout() -> void:
	var k = $spear.duplicate()
	$traviling_projectlies.add_child(k)
	k.go = true
	pass # Replace with function body.
