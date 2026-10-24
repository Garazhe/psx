extends Node

@onready var actor: CharacterBody3D = get_parent()
@onready var ray: RayCast3D = $"../Camera3D/InteractRay"
@onready var pickup: PickupController = $"../PickupController"
var interaction_requested := false
var throw_requested := false
var distance_steps := 0.0

func _ready() -> void:
	ray.add_exception(actor)

func _unhandled_input(event: InputEvent) -> void:
	if actor.interaction_enabled and pickup.is_holding():
		var step := 0.0
		if event.is_action_pressed("pickup_closer"):
			step = -1.0
		elif event.is_action_pressed("pickup_farther"):
			step = 1.0
		if step != 0.0:
			if event is InputEventMouseButton and event.factor > 0.0:
				step *= event.factor
			distance_steps += step
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("throw_item") and actor.interaction_enabled and pickup.is_holding():
		throw_requested = true
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_interact") and not event.is_echo() and actor.interaction_enabled:
		interaction_requested = true
		get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	var pending_steps := distance_steps
	distance_steps = 0.0
	if not actor.interaction_enabled:
		interaction_requested = false
		throw_requested = false
		pickup.release()
		return
	if throw_requested:
		throw_requested = false
		interaction_requested = false
		pickup.throw_held()
		return
	if not interaction_requested:
		pickup.adjust_distance(pending_steps)
		return
	interaction_requested = false
	if pickup.is_holding():
		pickup.release()
		return
	# Dialogue areas are triggers, not physical obstructions. First test bodies
	# only: walls still block pickup, even when a trigger surrounds the box.
	var include_areas := ray.collide_with_areas
	ray.collide_with_areas = false
	ray.force_raycast_update()
	var physical_target := ray.get_collider() as Node
	ray.collide_with_areas = include_areas
	if physical_target is PickupBody3D:
		pickup.pick_up(physical_target)
		return
	ray.force_raycast_update()
	var target := ray.get_collider() as Node
	if target is PickupBody3D:
		pickup.pick_up(target)
		return
	if target != null and target.has_method("action"):
		actor.start_dialogue(target)
		return
	if target != null and target.name == "test_cube":
		States.evil_bruh = not States.evil_bruh
		return
	# Existing dialogue colliders are children of the dialogue trigger.
	while target != null and target != get_tree().current_scene:
		if target.has_method("dialog_start"):
			target.dialog_start(actor)
			return
		target = target.get_parent()
