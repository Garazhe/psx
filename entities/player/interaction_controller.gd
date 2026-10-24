extends Node

@onready var actor: CharacterBody3D = get_parent()
@onready var ray: RayCast3D = $"../Camera3D/InteractionRay"
@onready var pickup: PickupController = $"../PickupController"
var interaction_requested := false

func _ready() -> void:
	ray.add_exception(actor)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_interact") and not event.is_echo() and actor.interaction_enabled:
		interaction_requested = true
		get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	if not actor.interaction_enabled:
		interaction_requested = false
		pickup.release()
		return
	if not interaction_requested:
		return
	interaction_requested = false
	if pickup.is_holding():
		pickup.release()
		return
	ray.force_raycast_update()
	var target := ray.get_collider() as Node
	if target is PickupBody3D:
		pickup.pick_up(target)
		return
	# Existing dialogue colliders are children of the dialogue trigger.
	while target != null and target != get_tree().current_scene:
		if target.has_method("dialog_start"):
			target.dialog_start(actor)
			return
		target = target.get_parent()
