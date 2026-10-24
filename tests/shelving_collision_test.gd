extends SceneTree

const SHELF_SCALE := 0.315 # Stash room's 0.9 scale times shelving's 0.35.
const BOARD_TOPS := [2.688871, 5.149371, 7.609971]
var world: Node3D
var shelf: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		# Stop this coroutine immediately after scheduling failure exit.
		await process_frame

func new_box(at: Vector3) -> PickupBody3D:
	var box: PickupBody3D = load("res://entities/pickups/box.tscn").instantiate()
	world.add_child(box)
	box.position = at
	return box

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	shelf = load("res://assets/models/pvz_stash/shelving/Shelving.glb").instantiate()
	world.add_child(shelf)
	shelf.scale = Vector3.ONE * SHELF_SCALE
	var shape_count := 0
	for mesh in shelf.get_children():
		for body in mesh.get_children():
			if body is StaticBody3D:
				for collision in body.get_children():
					if collision is CollisionShape3D:
						await check(collision.shape is BoxShape3D, "Shelf collision must be solid")
						shape_count += 1
	await check(shape_count == 7, "Expected three boards and four posts")

	# Boxes must rest on all three real imported boards, without any pickup code.
	var drops: Array[PickupBody3D] = []
	for height in BOARD_TOPS:
		drops.append(new_box(Vector3(1.13, height * SHELF_SCALE + 0.37, -0.47)))
	for i in range(120):
		await physics_frame
	for i in drops.size():
		await check(absf(drops[i].position.y - (BOARD_TOPS[i] * SHELF_SCALE + 0.3)) < 0.04,
			"Box fell through board %d" % i)
		print("PASS: resting on shelf ", i + 1)
		drops[i].queue_free()
	await process_frame

	# Upper shelf must also block a box thrown from underneath.
	var top: float = BOARD_TOPS[2] * SHELF_SCALE
	var upward := new_box(Vector3(1.13, top - 0.55, -0.47))
	upward.linear_velocity = Vector3.UP * 8.0
	# Allow transient solver penetration at impact, but never passage through.
	for i in range(60):
		await physics_frame
		await check(upward.position.y < top - 0.2, "Upward throw crossed shelf underside at frame %d: y=%f top=%f" % [i, upward.position.y, top])
	upward.queue_free()
	await process_frame
	print("PASS: shelf underside blocks upward throw")

	var sideways := new_box(Vector3(-0.8, 1.15, 0))
	sideways.gravity_scale = 0
	sideways.linear_velocity = Vector3.RIGHT * 8.0
	for i in range(60):
		await physics_frame
		await check(sideways.position.x < -0.23, "Throw crossed the corner post")
	sideways.queue_free()
	await process_frame
	print("PASS: thin corner post blocks fast box")

	# Preserve the open space between boards; do not replace the entire rack
	# with a single solid hull.
	var space := shelf.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(Vector3(1.13, 1.15, 1), Vector3(1.13, 1.15, -2))
	await check(space.intersect_ray(ray).is_empty(), "Gap between boards must remain open")
	print("PASS: gaps between shelves remain open")

	# Force the hold target below the upper board while the box is above it.
	var player = load("res://entities/player/player.tscn").instantiate()
	world.add_child(player)
	player.position = Vector3(1.13, 1.1, 1.33)
	player.set_physics_process(false)
	var held := new_box(Vector3(1.13, top + 0.4, -0.47))
	var controller: PickupController = player.get_node("PickupController")
	await check(controller.pick_up(held), "Pickup setup failed")
	for i in range(120):
		await physics_frame
		await check(held.position.y > top + 0.26, "Holding force pulled box through board")
	controller.release()
	print("PASS: holding force cannot pull box through board")
	world.queue_free()
	await process_frame
	await process_frame
	quit()
