class_name PickupController
extends Node

@export var max_mass := 15.0
@export var stiffness := 35.0
@export var damping := 12.0
@export var max_acceleration := 80.0
@export var break_distance := 4.0
@onready var hold_point: Marker3D = $"../Camera3D/HoldPoint"
var held_body: PickupBody3D

func is_holding() -> bool:
	return is_instance_valid(held_body)

func pick_up(body: PickupBody3D) -> bool:
	if is_holding() or not body.can_pick_up(max_mass):
		return false
	if body.global_position.distance_to(hold_point.global_position) > break_distance:
		return false
	held_body = body
	held_body.sleeping = false
	return true

func release() -> void:
	held_body = null

func _physics_process(_delta: float) -> void:
	if not is_holding():
		return
	var offset := hold_point.global_position - held_body.global_position
	if offset.length() > break_distance:
		release()
		return
	var acceleration := (offset * stiffness - held_body.linear_velocity * damping).limit_length(max_acceleration)
	held_body.apply_central_force(acceleration * held_body.mass)

func _exit_tree() -> void:
	release()
