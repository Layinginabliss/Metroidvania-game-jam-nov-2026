## Component for the player's attack
class_name AttackComponent extends Component

## The horizontal (x axis) attack area, that should be added as a child of this node.
## The collision box (of the area) should be [b]offset[/b] in relation to the parent Area2D's position.
@export var horizontal_attack_area : Area2D
## The vertical (y axis) attack area, that should be added as a child of this node.
## The collision box (of the area) should be [b]offset[/b] in relation to the parent Area2D's position.
@export var vertical_attack_area : Area2D


## The value of damage when attacking. This will be removed from the hit entity's health.
var damage_value : float = 10.0

## Where the entity is looking, most of the time. Private member that should be set by [method change_direction]
var _attack_direction : Vector2i = Vector2i(1, 0)

func _ready() -> void:
	assert(get_parent() is Entity, "AttackComponent has a parent that isn't an Entity")
	component_owner = get_parent() as Entity

## Attacks on the current direction the entity is facing. Internally, it checks for other [Entity] nodes inside the attack hitboxes (areas).
func attack() -> void:
	var area_to_check : Area2D = vertical_attack_area
	if (_attack_direction.x != 0):
		area_to_check = horizontal_attack_area # horizontal takes priority
	
	for body in area_to_check.get_overlapping_bodies():
		if body is not Entity: continue
		if body == component_owner: continue # avoid hitting yourself
		body.damage(damage_value)
	
	# DEBUG
	area_to_check.get_node("CollisionShape2D").debug_color = Color(0.775, 0.543, 0.0, 0.525)
	await get_tree().create_timer(0.2, true).timeout
	area_to_check.get_node("CollisionShape2D").debug_color = Color("0099b36b")

## Changes the attack areas to face where the entity is facing. Private member that is called by [method change_direction].
func _update_attack_areas():
	if (horizontal_attack_area == null): push_warning("Horizontal attack area not defined for an AttackComponent."); return
	if (vertical_attack_area == null): push_warning("Vertical attack area not defined for an AttackComponent."); return
	
	if (_attack_direction.x == -1): horizontal_attack_area.global_rotation = PI
	elif (_attack_direction.x == 1): horizontal_attack_area.global_rotation = 0
	
	if (_attack_direction.y == -1): vertical_attack_area.global_rotation = PI
	elif (_attack_direction.y == 1): vertical_attack_area.global_rotation = 0

## Changes the direction of attack by updating the attack areas.
func change_direction(direction: Vector2i):
	if (direction == Vector2i.ZERO): return
	
	_attack_direction = direction
	
	_update_attack_areas()
