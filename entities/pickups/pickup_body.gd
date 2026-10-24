class_name PickupBody3D
extends RigidBody3D

@export var pickup_enabled := true

func can_pick_up(max_mass: float) -> bool:
	return pickup_enabled and not freeze and mass <= max_mass
