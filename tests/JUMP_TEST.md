# Jump test level

Open `Scenes/jump_test.tscn` and press F6 to run this earlier test. F5 now launches `Scenes/floating_town.tscn`.

The course contains ten numbered platforms, using the existing imported `table1`, `table2`, `sofa1`, `Sports Car1`, `Cargo Train`, and `Large Building` GLB assets from `Assets/assets model 3d/`. Static triangle collisions match the visible imported meshes. Asset instances are uniformly scaled and centered, including models exported with offset origins. Platforms and their asset transforms remain editable in the Godot scene tree.

The route rises from 0 m to a roof at 4.30 m, with gaps from 0.65 m to 1.45 m. Floating platform text has been removed. The layout manifest records gaps and landing heights. Actual mesh surfaces vary: the sofa has a backrest, the car/train roofs are curved, and the building roof has a 0.30 m rim. These features require aiming and braking as well as jumping.

WASD walks, Shift runs, Space jumps, and the mouse controls the third-person camera. Release WASD before landing on the smaller platforms to slow down. R resets progress, timer and fall count. Esc releases the cursor; click to recapture it. The HUD reports height, time, falls, and the last completed jump's height/distance. Falling below -8 m returns Aof to the first platform. Landing on platform 10 completes the course and stops the timer.

To regenerate the scene, adjust `DATA` in `tools/build_jump_test.gd`, then run:

    godot --headless --path . --script res://tools/build_jump_test.gd --log-file ./jump-build.log

Regeneration replaces direct edits to the generated scene. `tests/jump_test_layout.json` records platform positions and footprints.

Physics verification:

    godot --headless --path . --scene res://tests/jump_level_test.tscn --quit-after 1200 --log-file ./jump-level-test.log

The integration test uses Aof's capsule and movement settings to simulate each running jump against the actual asset colliders, with air braking before landing. It verifies all nine gaps, safe spawning, completion, restarting and fall recovery. This is physics validation; it does not replace testing mouse/keyboard feel or visual layout interactively.
