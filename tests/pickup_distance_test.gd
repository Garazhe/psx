extends SceneTree

var world: Node3D
var player: CharacterBody3D
var box: PickupBody3D
var pickup: PickupController
var camera: Camera3D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		await process_frame

func frames(count: int) -> void:
	for i in count:
		await physics_frame
	await process_frame

func scroll(button: MouseButton, count := 1, factor := 1.0) -> void:
	for i in count:
		var event := InputEventMouseButton.new()
		event.button_index = button
		event.pressed = true
		event.factor = factor
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	await frames(3)

func check_distance() -> void:
	await check(absf(box.global_position.distance_to(camera.global_position) - pickup.hold_distance) < 0.005,
		"Held distance differs from selected distance: actual=%f selected=%f" % [box.global_position.distance_to(camera.global_position), pickup.hold_distance])

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	player = load("res://entities/player/player.tscn").instantiate()
	world.add_child(player)
	# Match the scaled Player used by Test Room: distance must still be in metres.
	player.scale = Vector3.ONE * 1.085188
	player.set_physics_process(false)
	camera = player.get_node("Camera3D")
	pickup = player.get_node("PickupController")
	box = load("res://entities/pickups/box.tscn").instantiate()
	world.add_child(box)
	box.position = Vector3(0, 0.8, -2.0)
	var original_mode := box.freeze_mode
	var original_ccd := box.continuous_cd
	await check(pickup.pick_up(box), "Pickup failed")
	await frames(3)
	await check_distance()
	var initial_distance := pickup.hold_distance
	await scroll(MOUSE_BUTTON_WHEEL_UP)
	await check(is_equal_approx(pickup.hold_distance, initial_distance - pickup.distance_step), "Wheel up must move closer")
	await check_distance()
	await scroll(MOUSE_BUTTON_WHEEL_DOWN)
	await check(is_equal_approx(pickup.hold_distance, initial_distance), "Wheel down must move farther")
	await scroll(MOUSE_BUTTON_WHEEL_UP, 1, 0.5)
	await check(is_equal_approx(pickup.hold_distance, initial_distance - pickup.distance_step * 0.5), "High-resolution scroll factor must be respected")
	await scroll(MOUSE_BUTTON_WHEEL_UP, 50)
	await check(is_equal_approx(pickup.hold_distance, pickup.min_hold_distance), "Near distance must be clamped")
	await check_distance()
	await scroll(MOUSE_BUTTON_WHEEL_DOWN, 50)
	await check(is_equal_approx(pickup.hold_distance, pickup.max_hold_distance), "Far distance must be clamped")
	await check_distance()
	print("PASS: real wheel events, direction, fine scrolling and both distance limits")

	for i in range(30):
		player.position += Vector3(0.08, 0, -0.08)
		player.rotate_y(0.02)
		await frames(1)
		await check_distance()
	print("PASS: rigid distance while moving and turning, including scaled Player")

	# An obstacle must override selected distance, then distance must recover
	# when it is removed. Place it between the camera and a nearby held box.
	await scroll(MOUSE_BUTTON_WHEEL_UP, 50)
	var wall := StaticBody3D.new()
	var wall_collision := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(5, 5, 0.1)
	wall_collision.shape = wall_shape
	wall.add_child(wall_collision)
	world.add_child(wall)
	wall.global_transform = Transform3D(camera.global_basis.orthonormalized(), camera.global_position - camera.global_basis.z.normalized() * 1.6)
	await frames(2)
	await scroll(MOUSE_BUTTON_WHEEL_DOWN, 50)
	await check(box.global_position.distance_to(camera.global_position) < 1.3, "Scroll must not push box through wall")
	await check(is_equal_approx(pickup.hold_distance, pickup.max_hold_distance), "Obstacle must not overwrite desired distance")
	wall.queue_free()
	await frames(3)
	await check_distance()
	print("PASS: scrolling respects wall and restores selected distance after obstacle")

	pickup.release()
	await check(not box.freeze and box.freeze_mode == original_mode and box.continuous_cd == original_ccd,
		"Release must restore dynamic body settings")
	var idle_distance := pickup.hold_distance
	await scroll(MOUSE_BUTTON_WHEEL_UP)
	await check(is_equal_approx(pickup.hold_distance, idle_distance), "Wheel without held item must do nothing")
	box.position = camera.global_position - camera.global_basis.z.normalized() * 2.0
	box.linear_velocity = Vector3.ZERO
	await check(pickup.pick_up(box), "Second pickup failed")
	player.interaction_enabled = false
	await scroll(MOUSE_BUTTON_WHEEL_UP)
	await check(not pickup.is_holding() and not box.freeze, "Dialogue must release body and ignore scrolling")
	player.interaction_enabled = true
	box.position = camera.global_position - camera.global_basis.z.normalized() * 2.0
	box.linear_velocity = Vector3.ZERO
	await check(pickup.pick_up(box), "Third pickup failed")
	await frames(3)
	player.queue_free()
	await frames(3)
	await check(not box.freeze and not box.hold_active, "Deleting player must unfreeze held body")
	print("PASS: release, idle wheel, dialogue blocking and player deletion")
	world.queue_free()
	await frames(2)
	quit()
