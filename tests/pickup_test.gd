extends SceneTree
func _initialize():
	call_deferred("run_test")
func run_test():
	var world = Node3D.new()
	root.add_child(world)
	current_scene = world
	var player = load("res://entities/player/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	var box = load("res://entities/pickups/box.tscn").instantiate()
	world.add_child(box)
	box.gravity_scale = 0
	box.position = Vector3(0, 0.74, -2.6)
	var controller = player.get_node("PickupController")
	box.mass = 100
	assert(not controller.pick_up(box))
	box.mass = 2
	assert(controller.pick_up(box))
	var before = box.global_position.distance_to(player.get_node("Camera3D/HoldPoint").global_position)
	for i in range(90):
		await physics_frame
	assert(box.global_position.distance_to(player.get_node("Camera3D/HoldPoint").global_position) < before * 0.2)
	assert(box.get_collision_exceptions().has(player))
	controller.release()
	assert(not controller.is_holding())
	assert(not box.get_collision_exceptions().has(player))
	assert(controller.pick_up(box))
	player.interaction_enabled = false
	await physics_frame
	await physics_frame
	assert(not controller.is_holding())
	player.interaction_enabled = true
	assert(controller.pick_up(box))
	controller.throw_held()
	await physics_frame
	await physics_frame
	assert(box.linear_velocity.z < -5.0)
	box.linear_velocity = Vector3.ZERO
	box.position = Vector3(0, 0.74, -1.2)
	assert(controller.pick_up(box))
	var wall = StaticBody3D.new()
	var wall_shape = CollisionShape3D.new()
	var wall_box = BoxShape3D.new()
	wall_box.size = Vector3(5, 5, 0.2)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	world.add_child(wall)
	wall.position = Vector3(0, 0, -2.1)
	controller.hold_distance = 3.0
	for i in range(90):
		await physics_frame
	assert(box.position.z > -1.8, "Held box must remain on the near side of wall")
	controller.release()
	box.position = player.position
	box.linear_velocity = Vector3.ZERO
	assert(controller.pick_up(box))
	controller.release()
	assert(box.get_collision_exceptions().has(player))
	box.position = Vector3(0, 1, -1.3)
	await physics_frame
	await physics_frame
	assert(not box.get_collision_exceptions().has(player))
	assert(controller.pick_up(box))
	box.queue_free()
	await process_frame
	assert(not controller.is_holding())
	print("PASS: mass limit, hold, throw, wall, collision restoration, dialogue lock, deleted body")
	quit()
