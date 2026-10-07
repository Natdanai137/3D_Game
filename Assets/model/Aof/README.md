# Aof body rig

`Aof_3D.glb` is the original supplied model. `Aof_Rigged.glb` is the playable copy with its embedded textures, a 22-bone body skeleton and four normalized bone influences per vertex. It is normalized to 1.8 m high, with feet at Y=0 and forward along +Z.

The skeleton covers root, hips, spine, chest, neck, head, shoulders, upper/lower arms, hands, upper/lower legs, feet and toes. This is a basic body rig; fingers and facial features do not have separate animation controls.

The supplied mesh has small fused contact bridges between hanging hands and trousers. The rigged copy disconnects 82 of 112,930 triangles at those contacts to prevent stretched ribbons during arm movement. Original positions, UVs, textures and source GLB remain available in the original file.

Clips: Idle, Walk, Run, Jump and Fall. `AofPlayer.tscn` wraps the imported GLB with `Scripts/AofRigVisual.gd`, which selects clips from the existing player controller. `Scenes/player.tscn` and `Scenes/AofPreview.tscn` now use this wrapper. Walk/run clips loop and scale playback speed with movement; rising/falling poses blend according to vertical velocity. These are generated starter animations that can be refined in a 3D editor.

Press F5 to use the rigged Aof in Floating Town, with three jumps between landings and Uncle Oli checkpoints. Controls: WASD walk, Shift run, Space jump, mouse orbit, R return to the current checkpoint. The physics capsule remains 1.8 m high; the player now has a three-jump budget restored on landing.

Regenerate with bundled Python plus NumPy/Pillow:

    python tools/rig_aof.py

Then let Godot reimport `Aof_Rigged.glb`. Regeneration replaces that generated file and its clips, so save manually refined variants under a separate filename. `Aof_Rigged.rig.json` records bone names and weight checks.

Render pose previews without a desktop graphics window:

    python tools/preview_aof_rig.py

The resulting `rig_preview.png` shows software-rendered skinning poses; it is not a screenshot of the in-game renderer.

Verify the imported Godot skin, rest transforms, normalized weights and all five movement states:

    godot --headless --path . --scene res://tests/aof_rig_test.tscn --quit-after 300 --log-file ./aof-rig-test.log
