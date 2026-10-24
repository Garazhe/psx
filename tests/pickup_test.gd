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
	controller.release()
	assert(not controller.is_holding())
	assert(controller.pick_up(box))
	player.interaction_enabled = false
	await physics_frame
	await physics_frame
	assert(not controller.is_holding())
	player.interaction_enabled = true
	assert(controller.pick_up(box))
	box.queue_free()
	await process_frame
	assert(not controller.is_holding())
	print("PASS: mass limit, physical hold, release, dialogue lock, deleted body")
	quit()
