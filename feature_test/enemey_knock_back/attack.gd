extends Area2D

var inside_area = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect('area_entered',_on_area_entered)
	connect('area_exited',_on_area_exited)
	connect('body_entered',_on_body_entered)
	connect('body_exited',_on_body_exited)
	$cool_down/attack_cool_down.connect('timeout',_on_attack_cool_down_timeout)

var inside_body = null

func damge():
	if not $cool_down.visible and inside_body != null:
		#print('attempted to attack ',inside_area)
		
		inside_body.damge(get_parent())
		
		#var viewport_size = get_viewport_rect().size

		#inside_area.global_position = Vector2(
			#randf_range(0, viewport_size.x),
			#randf_range(0, viewport_size.y)
		#)

		$cool_down.visible = true
		$cool_down/attack_cool_down.start()

func _on_area_entered(area: Area2D) -> void:
	inside_area = area
	pass # Replace with function body.


func _on_area_exited(area: Area2D) -> void:
	if area == inside_area:
		inside_area = null
	pass # Replace with function body.


func _on_attack_cool_down_timeout() -> void:
	$cool_down.visible = false
	pass # Replace with function body.


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemy'):
		inside_body = body # if the body is an enemy


func _on_body_exited(body: Node2D) -> void:
	if inside_body == body:
		inside_body = null
