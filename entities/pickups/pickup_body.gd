class_name PickupBody3D
extends RigidBody3D

@export var pickup_enabled := true
var holder: Node
var ignored_actor: PhysicsBody3D
var owns_exception := false
var saved_ccd := false
var saved_freeze := false
var saved_freeze_mode := FREEZE_MODE_STATIC
var hold_active := false
var carry_velocity := Vector3.ZERO

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
	saved_freeze = freeze
	saved_freeze_mode = freeze_mode
	continuous_cd = true
	freeze_mode = FREEZE_MODE_KINEMATIC
	freeze = true
	hold_active = true
	carry_velocity = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = false

func move_held(destination: Vector3, orientation: Quaternion, turn_speed: float, delta: float) -> void:
	if not hold_active:
		return
	var before := global_position
	# Swept movement uses the actual shapes, so even a large camera turn cannot
	# teleport a box through a wall. Blocking contact takes priority over distance.
	move_and_collide(destination - global_position, false, 0.002)
	_rotate_held(orientation, turn_speed * delta)
	# Do not turn scroll steps or fast mouse turns into an enormous release kick.
	carry_velocity = ((global_position - before) / maxf(delta, 0.001)).limit_length(10.0)

func _rotate_held(orientation: Quaternion, max_angle: float) -> void:
	var current := global_basis.get_rotation_quaternion()
	var angle := current.angle_to(orientation)
	if angle < 0.0001:
		return
	var destination := current.slerp(orientation, minf(1.0, max_angle / angle))
	# Test small rotation increments: testing only the final orientation could
	# let corners pass through thin shelves between equivalent orientations.
	var steps := maxi(1, ceili(current.angle_to(destination) / deg_to_rad(3.0)))
	var body_scale := global_basis.get_scale()
	for i in range(1, steps + 1):
		var candidate := Transform3D(Basis(current.slerp(destination, float(i) / steps)).scaled(body_scale), global_position)
		if not _rotation_is_clear(candidate):
			break
		global_transform = candidate

func _rotation_is_clear(candidate: Transform3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	if is_instance_valid(ignored_actor):
		query.exclude = [get_rid(), ignored_actor.get_rid()]
	for child in get_children():
		if child is CollisionShape3D and not child.disabled and child.shape != null:
			query.shape = child.shape
			query.transform = candidate * child.transform
			if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
				return false
	return true

func end_hold() -> void:
	if not hold_active:
		return
	hold_active = false
	holder = null
	freeze_mode = saved_freeze_mode
	freeze = saved_freeze
	continuous_cd = saved_ccd
	linear_velocity = carry_velocity
	angular_velocity = Vector3.ZERO
	sleeping = false
	_try_restore_collision()

func _physics_process(_delta: float) -> void:
	if hold_active and not is_instance_valid(holder):
		end_hold()
	if not hold_active and is_instance_valid(ignored_actor):
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
	end_hold()
	if is_instance_valid(ignored_actor) and owns_exception:
		remove_collision_exception_with(ignored_actor)
