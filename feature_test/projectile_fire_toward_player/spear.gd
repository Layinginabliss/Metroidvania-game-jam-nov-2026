
extends Area2D

var go = false
var speed = 1000.0

@export var freeze_on_static_hit = true
@export var despawn_time = 10.0


func call_despawn():
	await get_tree().create_timer(despawn_time).timeout # only excute if it's duplucetd
	queue_free()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# Self destruct after 10 seconds


func _process(delta: float) -> void:
	if go:
		var forward = global_transform.x
		global_position += forward * speed * delta


func _on_body_entered(body: PhysicsBody2D) -> void:
	if freeze_on_static_hit and body is StaticBody2D:
		go = false
		#print("Spear stopped by: ", body.name)
