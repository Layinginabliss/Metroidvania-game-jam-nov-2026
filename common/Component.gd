## Components are meant to be used strictly for [Entity] nodes.
class_name Component extends Node2D

@export var component_owner : Entity
@export var enabled : bool = true

## Called every process frame, if the component is enabled.
@warning_ignore("unused_parameter")
func _component_process(delta: float) -> void:
	pass
	
## Called every physics frame, if the component is enabled.
@warning_ignore("unused_parameter")
func _component_physics(delta: float) -> void:
	pass

func _process(delta: float) -> void:
	if enabled: _component_process(delta)

func _physics_process(delta: float) -> void:
	if enabled: _component_physics(delta)
