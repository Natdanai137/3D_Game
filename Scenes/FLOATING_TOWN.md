# Floating Town

Press F5 to open the main menu, then select Start to enter `floating_town.tscn`. The first zone has 18 ascending platforms up to a street at 20.8 m. Houses, streets, parked vehicles, tables, a sofa, train roofs and building roofs form the route. Imported town props are referenced from `Assets/assets model 3d/`. The actual asset meshes supply static collisions, with wide street decks used for rest stops.

There are three Uncle Oli checkpoints on the first, sixth and twelfth platforms. Stand on the colored ring to activate the next checkpoint. The active ring turns green. Passing above a ring while airborne does not save. Older checkpoints cannot replace a later one. Checkpoints are kept for the current play session.

Falling below Y=-12 returns Aof to the latest checkpoint, clearing velocity, restoring the jump budget and snapping the camera. R returns to that checkpoint without counting a fall. Height, elapsed time, falls, checkpoint progress and remaining jumps are displayed in the HUD. No text labels float above the platforms; labels have also been removed from the earlier jump-test scene and its generator.

Press Space separately for each of three consecutive jumps. Each jump resets upward velocity to 6 m/s. Landing restores all three. Walking off an edge uses the ground jump when the coyote window expires. WASD walks, Shift runs, and the mouse orbits. Esc releases the cursor; click to resume control.

Reaching the final street marks Floating Town complete. The gate at its end marks the intended route to Cloud Sea; a Cloud Sea level has not been authored yet.

The saved scene contains editable platform nodes, asset instances, collision shapes, street decoration, checkpoints and NPCs. To regenerate, change ROUTE in `tools/build_floating_town.gd` and run:

    godot --headless --path . --script res://tools/build_floating_town.gd --log-file ./floating-town-build.log

Regeneration replaces direct scene edits. The layout is recorded in `tests/floating_town_layout.json`.

Verify three-jump limits and replenishment, all checkpoints, airborne checkpoint rejection, death recovery, camera respawn, absence of floating text, all 17 route gaps, and zone completion:

    godot --headless --path . --scene res://tests/floating_town_test.tscn --quit-after 6000 --log-file ./floating-town-test.log

The physics test calls the same jump-budget methods used by the controller and simulates running movement and air braking against the actual collisions. Keyboard/mouse feel and the live rendered appearance still need interactive playtesting.

