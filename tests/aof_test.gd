extends Node3D

var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
	print(('PASS: ' if ok else 'FAIL: ') + message)

func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run this test with a display: mouse capture is unavailable in headless mode.")
		get_tree().quit(2)
		return
	var ground := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	collider.shape = box
	ground.position.y = -0.5
	ground.add_child(collider)
	add_child(ground)
	var player = load('res://Scenes/player.tscn').instantiate()
	add_child(player)
	await frames(30)
	check(player.is_on_floor(), 'Aof settles on ground')
	check(player.get_node('CharacterModel/Rig/Skeleton3D/AofMesh').skin != null, 'Replacement Aof model loads')
	check(InputMap.action_get_events('sprint')[0].physical_keycode == KEY_SHIFT, 'Shift mapped to sprint')
	Input.action_press('move_forward')
	await frames(60)
	check(absf(player.velocity.z + 3.5) < 0.1, 'W walks at 3.5 m/s')
	Input.action_press('sprint')
	await frames(60)
	check(absf(player.velocity.z + 6.0) < 0.1, 'Shift runs at 6 m/s')
	Input.action_press('move_right')
	await frames(30)
	check(absf(Vector2(player.velocity.x, player.velocity.z).length() - 6.0) < 0.1, 'Diagonal movement normalized')
	Input.action_release('move_right')
	Input.action_release('move_forward')
	Input.action_release('sprint')
	await frames(30)
	Input.action_press('jump')
	await frames(3)
	Input.action_release('jump')
	check(player.velocity.y > 0.0 and not player.is_on_floor(), 'Space jumps off ground')
	Input.action_press('jump')
	await frames(3)
	Input.action_release('jump')
	check(player.jumps_used == 2, 'Second jump works in midair')
	Input.action_press('jump')
	await frames(3)
	Input.action_release('jump')
	check(player.jumps_used == 3, 'Third jump works in midair')
	Input.action_press('jump')
	await frames(3)
	Input.action_release('jump')
	check(player.jumps_used == 3, 'Fourth jump is blocked')
	await frames(75)
	check(player.is_on_floor(), 'Jump lands back on ground')
	player.velocity = Vector3(2,-25,4)
	player.reset_to_spawn(Vector3(0,2,0))
	check(player.velocity == Vector3.ZERO, 'Respawn clears fall velocity')
	check(player.get_node('Gimbal').global_position.distance_to(Vector3(0,3.25,0)) < 0.01, 'Camera snaps to respawn')
	await frames(50)
	var wall := StaticBody3D.new()
	var wall_collision := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(5,5,.3)
	wall_collision.shape = wall_box
	wall.add_child(wall_collision)
	wall.position = Vector3(0,2,2)
	add_child(wall)
	await frames(15)
	check(player.get_node('Gimbal/SpringArm3D').get_hit_length() < 3.0, 'Camera retracts before wall')
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.action_press('move_forward')
	await frames(30)
	check(Vector2(player.velocity.x,player.velocity.z).length() < 0.1, 'Released cursor disables movement')
	Input.action_release('move_forward')
	print('AOF TESTS: %s' % ('ALL PASSED' if failures.is_empty() else str(failures)))
	if DisplayServer.get_name() != "headless":
		player.queue_free()
		ground.queue_free()
		wall.queue_free()
		var preview = load("res://Scenes/AofPreview.tscn").instantiate()
		add_child(preview)
		await frames(10)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://Assets/Models/Aof/preview.png")
	get_tree().quit(0 if failures.is_empty() else 1)
