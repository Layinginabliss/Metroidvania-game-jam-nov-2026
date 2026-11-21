extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@export var speed = 100
@export var attack_to : Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed('enemy_attack'):
		global_position = attack_to.global_position
		move = true
	if move:
		global_position +=  $door_col.global_position.direction_to($move_toward.global_position) * speed * delta
		#TODO : stop when reached position and despawn door
	pass

var move = false
