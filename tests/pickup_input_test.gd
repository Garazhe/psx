extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	change_scene_to_file("res://levels/Floor_1/test_room/floor.tscn")
	await scene_changed
	for i in range(120):
		await physics_frame
	var p = current_scene.get_node("Player")
	var b = current_scene.get_node("PickupBox")
	var c = p.get_node("Camera3D")
	c.look_at(b.global_position)
	await physics_frame
	var ray = c.get_node("InteractRay")
	ray.force_raycast_update()
	print("camera=",c.global_position," box=",b.global_position," distance=",c.global_position.distance_to(b.global_position)," ray=",ray.get_collider())
	var original_y: float = b.global_position.y
	var e = InputEventKey.new()
	e.physical_keycode = KEY_E
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	for i in range(3):
		await physics_frame
	assert(p.get_node("PickupController").is_holding(), "E must pick up the box through a dialogue trigger")
	assert(p.interaction_enabled, "Pickup must not start a dialogue")
	for i in range(120):
		await physics_frame
	assert(b.global_position.y > original_y + 0.15, "Box must actually lift off the floor")
	e = InputEventKey.new()
	e.physical_keycode = KEY_E
	e.pressed = false
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await physics_frame
	e = InputEventKey.new()
	e.physical_keycode = KEY_E
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	for i in range(3):
		await physics_frame
	assert(not p.get_node("PickupController").is_holding(), "Second E must release")
	print("PASS: real E input picks up and releases through dialogue area")
	quit()
