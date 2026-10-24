class_name PickupBody3D
extends RigidBody3D

@export var pickup_enabled := true
var holder: Node
var ignored_actor: PhysicsBody3D
var owns_exception := false
var saved_ccd := false

func can_pick_up(max_mass: float) -> bool:
	return pickup_enabled and not freeze and mass <= max_mass and not is_instance_valid(holder) and not is_instance_valid(ignored_actor)

# Conservative bounding sphere includes all enabled primitive collision shapes.
func pickup_radius() -> float:
	var radius := 0.0
	for child in get_children():
		if child is CollisionShape3D and not child.disabled and child.shape != null:
			var bounds: AABB = child.shape.get_debug_mesh().get_aabb()
			var local_radius := 0.0
			# Farthest AABB corner, including offset and local scale.
			for corner in range(8):
				local_radius = maxf(local_radius, (child.transform * bounds.get_endpoint(corner)).length())
			radius = maxf(radius, local_radius)
	var body_scale := global_basis.get_scale().abs()
	return radius * maxf(body_scale.x, maxf(body_scale.y, body_scale.z))

func begin_hold(controller: Node, actor: PhysicsBody3D) -> void:
	holder = controller
	ignored_actor = actor
	owns_exception = not get_collision_exceptions().has(actor)
	if owns_exception:
		add_collision_exception_with(actor)
	saved_ccd = continuous_cd
	continuous_cd = true
	sleeping = false

func end_hold() -> void:
	holder = null
	continuous_cd = saved_ccd
	_try_restore_collision()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(holder) and is_instance_valid(ignored_actor):
		_try_restore_collision()

func _try_restore_collision() -> void:
	if not is_instance_valid(ignored_actor):
		ignored_actor = null
		return
	var sphere := SphereShape3D.new()
	sphere.radius = maxf(pickup_radius(), 0.05)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.collision_mask = ignored_actor.collision_layer
	query.exclude = [get_rid()]
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 64):
		if hit.collider == ignored_actor:
			return
	if owns_exception:
		remove_collision_exception_with(ignored_actor)
	ignored_actor = null
	owns_exception = false

func _exit_tree() -> void:
	if is_instance_valid(ignored_actor) and owns_exception:
		remove_collision_exception_with(ignored_actor)
