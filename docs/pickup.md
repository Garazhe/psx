# Physics pickup

E picks up/releases; left mouse throws. Open Test Room from the main menu.
Select Player/PickupController (enable editable children for a level instance) to tune:

- hold_distance: 1.8 m; desired distance, shortened by obstacles.
- stiffness: 35; increase for a more responsive hold.
- damping: 12; increase if oscillating, decrease if sluggish.
- target_speed: 8 m/s; limits target jumps during fast camera turns.
- rotation_stiffness / rotation_damping: 12 / 5; follows camera while preserving the pickup orientation.
- throw_speed: 8 m/s velocity increment, independent of mass.
- max_mass / max_radius: 15 kg / 0.8 m.

PickupBody3D requires enabled direct-child primitive CollisionShape3D nodes.
Use unit scale on rigid bodies; edit mesh/shape dimensions instead.
The wall sweep uses a conservative enclosing sphere, so rectangular objects may
stop earlier near walls. Initial contacts are left to the physics solver on the
body-to-target sweep so boxes can leave the floor. This is not a guarantee against
all clipping during extreme rotation or moving-geometry interactions.
Player collision exceptions are owned by the item and restored after separation,
even if the controller disappears. Pre-existing exceptions are preserved.

Validation: godot --headless --path . --script tests/pickup_test.gd
Checks include hold, mass limit, throw, wall obstruction, overlap-safe release,
dialogue lock, and deletion. Visual feel must still be tested in Godot.

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
