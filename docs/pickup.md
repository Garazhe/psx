# Physics pickup

E picks up/releases; left mouse throws. While holding, mouse wheel up moves the
box closer and wheel down moves it farther. Scrolling without a held item or
during dialogue does nothing. Open Test Room from the main menu.

Select Player/PickupController (enable editable children for a level instance) to tune:

- hold_distance: 1.8 m initially; remembers the last selected distance.
- min_hold_distance / max_hold_distance: 0.8 / 3.0 m.
- distance_step: 0.2 m per wheel notch (fractional wheel events are supported).
- rotation_speed: 8 rad/s; follows camera while preserving pickup orientation.
- throw_speed: 8 m/s velocity increment, independent of mass.
- max_mass / max_radius: 15 kg / 0.8 m.

The held body is temporarily frozen in kinematic mode. Each physics tick moves
it to the selected distance using move_and_collide with its actual collision
shapes. There is no spring lag in free space; distances are world metres even
when the Player is scaled. Obstacles take priority: the box stops closer when
blocked and returns to the selected distance when the path is clear.
Rotation advances in small increments and stops if the next orientation overlaps
geometry. This is not a guarantee against all clipping with extreme rotations
or moving geometry. Visual feel should still be tested in the editor.

PickupBody3D requires enabled direct-child primitive CollisionShape3D nodes.
Use unit scale on rigid bodies; edit mesh/shape dimensions instead.
A conservative sphere sweep from the camera further restricts the target near
walls. If that sphere already overlaps geometry, movement still uses the body's
actual-shape sweep rather than trapping the held box in place.

Release/throw restores freeze mode and CCD settings, resumes gravity and carries
bounded movement velocity. Deleting the controller also releases the body.
Player collision exceptions are owned by the item and restored after separation;
pre-existing exceptions are preserved. Freezing ends as soon as dialogue begins.

Validation commands:

    godot --headless --path . --script tests/pickup_test.gd
    godot --headless --path . --script tests/pickup_input_test.gd
    godot --headless --path . --script tests/pickup_distance_test.gd

These cover real E/wheel events, distance bounds, walking/turning without lag,
wall obstruction, release/throw, dialogue blocking and body/player deletion.

## After updating the project

Close the running game, open project.godot in the editor and wait for import.
Dialogue Manager must be enabled in Project Settings > Plugins. The .dialogue
sources need its importer; generated .godot/imported files are not committed.
If dialogue resources fail to load, close Godot and run:

    godot --headless --editor --path . --import

Then reopen the editor. Do not copy another machine's .godot cache.
The player uses one InteractRay and InteractionController for both pickup and
Dialogue Manager actions; do not replace the player scene with an older version.

## Shelving collision

`Shelving.glb` uses `shelving_import.gd` as a post-import script. The original
board trimeshes have inward-facing top faces and let rigid bodies fall through.
The script welds mesh seams, finds disconnected rectangular pieces and creates
seven solid box colliders: three boards and four posts. It preserves the spaces
between boards and applies to direct GLB instances as well as `shelving.tscn`.
If the source model is changed to non-rectangular pieces, review this collision
approximation and rerun `tests/shelving_collision_test.gd`.

After updating, allow Godot to reimport `Shelving.glb`. If an existing editor
session keeps the old colliders, select the GLB and click Reimport in the Import
dock, then restart the game. Generated `.godot` files are not versioned.

Regression: `godot --headless --path . --script tests/shelving_collision_test.gd`.
This tests all boards, an upward throw, a fast hit on a post, open shelf gaps,
and a held box pulled towards the opposite side of a board, at the stash-room
scale. Collision assertions allow the physics solver's transient contact slop.
