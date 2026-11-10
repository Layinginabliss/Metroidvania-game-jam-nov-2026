extends RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func depawn():
	$despawn_timer.start()

func _on_despawn_timer_timeout() -> void:
	queue_free() # later dramatic paricle effect
