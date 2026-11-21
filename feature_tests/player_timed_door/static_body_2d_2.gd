extends StaticBody2D

func _ready() -> void:
	$area_button.connect('body_entered',_on_area_button_body_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed('action') and not middle_of_transform and waiting_body != null:
		$area_button/Label.visible = false
		$transform_duration.start()
		middle_of_transform = true
		transform_node($door,$move_to.global_position,$move_to.rotation,$transform_duration.wait_time)

var middle_of_transform = false
@export var tween_trans_type = Tween.TRANS_SINE
@export var tween_trans_ease = Tween.TRANS_SINE
 

func transform_node(node: Node2D, target_position: Vector2, target_rotation: float, duration: float):
	var tween = create_tween()

	tween.set_parallel(true) 
	tween.set_trans(Tween.TRANS_SINE) # why does twenn never take tasfrom ? case 2d 3d incompatibly ?
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(node, "global_position", target_position, duration)
	tween.tween_property(node, "rotation", target_rotation, duration)

var waiting_body = null

func _on_area_button_body_entered(body: Node2D) -> void:
	if body.is_in_group('player'):
		waiting_body = body

#func _on_transform_duration_timeout() -> void: # close it later...
	#middle_of_transform = false
	#pass # Replace with function body.
