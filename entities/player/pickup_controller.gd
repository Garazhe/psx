class_name PickupController
extends Node

@export var max_mass := 15.0
@export_range(0.8, 3.0) var hold_distance := 1.8
@export var stiffness := 35.0
@export var damping := 12.0
@export var max_acceleration := 80.0
@export var target_speed := 8.0
@export var break_distance := 4.0
@export var max_radius := 0.8
@export var wall_margin := 0.08
@export var throw_speed := 8.0
@export var rotation_stiffness := 12.0
@export var rotation_damping := 5.0
@export var max_torque := 30.0
@onready var actor: CharacterBody3D = get_parent()
@onready var camera: Camera3D = $"../Camera3D"
@onready var hold_point: Marker3D = $"../Camera3D/HoldPoint"
var held_body: PickupBody3D
var target_position := Vector3.ZERO
var relative_rotation := Quaternion.IDENTITY
var radius := 0.0

func is_holding() -> bool:
	return is_instance_valid(held_body)

func pick_up(body: PickupBody3D) -> bool:
	if is_holding() or not body.can_pick_up(max_mass):
		return false
	radius = body.pickup_radius()
	if radius <= 0.0 or radius > max_radius or body.global_position.distance_to(camera.global_position) > 3.0:
		return false
	held_body = body
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
	body.apply_central_impulse(-camera.global_basis.z * throw_speed * body.mass)

func _safe_target(start: Vector3, destination: Vector3, departing := false) -> Vector3:
	var shape := SphereShape3D.new()
	shape.radius = radius + wall_margin
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, start)
	query.motion = destination - start
	query.collision_mask = held_body.collision_mask
	query.exclude = [held_body.get_rid(), actor.get_rid()]
	var space := held_body.get_world_3d().direct_space_state
	if not departing and not space.intersect_shape(query, 1).is_empty():
		return start
	var fraction := space.cast_motion(query)
	return start + query.motion * fraction[0]

func _physics_process(delta: float) -> void:
	if not is_holding():
		return
	if not actor.interaction_enabled or held_body.global_position.distance_to(camera.global_position) > break_distance:
		release()
		return
	hold_point.position.z = -hold_distance
	var desired := _safe_target(camera.global_position, hold_point.global_position)
	var next := target_position.move_toward(desired, target_speed * delta)
	# Sweep from the body as well: camera and box may be on opposite sides of a corner.
	target_position = _safe_target(held_body.global_position, next, true)
	var offset := target_position - held_body.global_position
	var gravity := Vector3(0, -float(ProjectSettings.get_setting("physics/3d/default_gravity")), 0) * held_body.gravity_scale
	var acceleration := (offset * stiffness - held_body.linear_velocity * damping - gravity).limit_length(max_acceleration)
	held_body.apply_central_force(acceleration * held_body.mass)
	var desired_rotation := camera.global_basis.get_rotation_quaternion() * relative_rotation
	var error := desired_rotation * held_body.global_basis.get_rotation_quaternion().inverse()
	if error.w < 0:
		error = -error
	var torque := error.get_axis() * error.get_angle() * rotation_stiffness - held_body.angular_velocity * rotation_damping
	held_body.apply_torque(torque.limit_length(max_torque))

func _exit_tree() -> void:
	release()
