## Class that represents all entities in the game, including the Player and the Enemies.
## Currently only groups them together; but in the future should maybe have something with unique IDs to use for level memory (i forgot the exact name of that mechanic but i hope you guys know what i mean)
class_name Entity extends CharacterBody2D

## Emitted when the entity is damaged, through [method damage].
signal entity_damaged(value: float)

@export var attack_component : AttackComponent

func damage(value: float) -> void:
	print("hi i received ", value, " damage")
