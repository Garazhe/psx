class_name PickupController
extends Node

@export var max_mass := 15.0
@export_range(0.8, 3.0) var hold_distance := 1.8
@export_range(0.5, 2.0) var min_hold_distance := 0.8
@export_range(2.0, 3.5) var max_hold_distance := 3.0
@export_range(0.05, 0.5) var distance_step := 0.2
@export var break_distance := 4.0
@export var max_radius := 0.8
@export var wall_margin := 0.08
@export var throw_speed := 8.0
@export var rotation_speed := 8.0
@onready var actor: CharacterBody3D = get_parent()
@onready var camera: Camera3D = $"../Camera3D"
@onready var hold_point: Marker3D = $"../Camera3D/HoldPoint"
var held_body: PickupBody3D
var target_position := Vector3.ZERO
var relative_rotation := Quaternion.IDENTITY
var radius := 0.0

func is_holding() -> bool:
	return is_instance_valid(held_body)

func adjust_distance(steps: float) -> void:
	if is_holding() and actor.interaction_enabled:
		hold_distance = clampf(hold_distance + steps * distance_step, min_hold_distance, max_hold_distance)

func pick_up(body: PickupBody3D) -> bool:
	if is_holding() or not body.can_pick_up(max_mass):
		return false
	radius = body.pickup_radius()
	if radius <= 0.0 or radius > max_radius or body.global_position.distance_to(camera.global_position) > 3.0:
		return false
	held_body = body
	hold_distance = clampf(hold_distance, min_hold_distance, max_hold_distance)
	target_position = body.global_position
	relative_rotation = camera.global_basis.get_rotation_quaternion().inverse() * body.global_basis.get_rotation_quaternion()
	body.begin_hold(self, actor)
	return true

func release() -> void:
	if is_holding():
		held_body.end_hold()
	held_body = null

func throw_held() -> void:
	if not is_holding():
		return
	var body := held_body
	release()
	body.apply_central_impulse(-camera.global_basis.z.normalized() * throw_speed * body.mass)

func _safe_target(start: Vector3, destination: Vector3) -> Vector3:
	var shape := SphereShape3D.new()
	shape.radius = radius + wall_margin
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, start)
	query.motion = destination - start
	query.collision_mask = held_body.collision_mask
	query.exclude = [held_body.get_rid(), actor.get_rid()]
	var space := held_body.get_world_3d().direct_space_state
	# If the camera sphere already overlaps nearby geometry, its sweep cannot
	# give a useful safe fraction. The body's actual-shape move_and_collide
	# still checks the entire path, including when lifting a box off the floor.
	if not space.intersect_shape(query, 1).is_empty():
		return destination
	var fraction := space.cast_motion(query)
	return start + query.motion * fraction[0]

func _physics_process(delta: float) -> void:
	if not is_holding():
		return
	if not actor.interaction_enabled or held_body.global_position.distance_to(camera.global_position) > break_distance:
		release()
		return
	hold_distance = clampf(hold_distance, min_hold_distance, max_hold_distance)
	hold_point.position.z = -hold_distance
	# Distance is measured in world metres even for a scaled Player instance.
	var direction := (hold_point.global_position - camera.global_position).normalized()
	target_position = _safe_target(camera.global_position, camera.global_position + direction * hold_distance)
	var desired_rotation := camera.global_basis.get_rotation_quaternion() * relative_rotation
	held_body.move_held(target_position, desired_rotation, rotation_speed, delta)

func _exit_tree() -> void:
	release()
