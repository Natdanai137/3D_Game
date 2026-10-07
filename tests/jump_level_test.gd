extends Node

var failures: Array[String] = []
var level: Node3D
var player: CharacterBody3D
var space: PhysicsDirectSpaceState3D

func check(ok: bool, message: String) -> void:
	print(('PASS: ' if ok else 'FAIL: ') + message)
	if not ok:
		failures.append(message)

func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func ground(x: float, z: float) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x,20,z),Vector3(x,-10,z),1,[player.get_rid()])
	return space.intersect_ray(query)

func _ready() -> void:
	level = load('res://Scenes/jump_test.tscn').instantiate()
	add_child(level)
	player = level.get_node('Player')
	player.set_physics_process(false)
	await frames(5)
	space = level.get_world_3d().direct_space_state
	var platforms: Array[Node] = level.get_node('Platforms').get_children()
	check(platforms.size() == 10, 'Ten imported asset platforms load')
	for body in platforms:
		var landing: Vector3 = body.get_meta('landing')
		var hit := ground(landing.x,landing.z)
		check(not hit.is_empty() and hit.collider == body and absf(hit.position.y - landing.y) < 0.02, '%s has actual mesh landing collision' % body.name)
		var size: Vector2 = body.get_meta('footprint')
		var heights: Array = []
		for fraction in [0.0,0.15,0.3,0.5,0.7,0.85,1.0]:
			var sample := ground(landing.x,landing.z + size.y * (fraction - 0.5) * 0.98)
			heights.append(snappedf(sample.position.y,0.01) if not sample.is_empty() else null)
		print('%s FRONT -> BACK SURFACE: %s' % [body.name, heights])
	for i in range(9):
		var source: StaticBody3D = platforms[i]
		var target: StaticBody3D = platforms[i+1]
		var origin: Vector3 = source.get_meta('landing')
		var destination: Vector3 = target.get_meta('landing')
		var footprint: Vector2 = source.get_meta('footprint')
		var takeoff_z := origin.z-footprint.y*0.5+0.30
		var hit := ground(destination.x,takeoff_z)
		if hit.is_empty():
			check(false, '%s takeoff surface exists' % source.name)
			continue
		player.reset_to_spawn(hit.position + Vector3.UP*0.015)
		player.velocity = Vector3.ZERO
		for j in range(8):
			await get_tree().physics_frame
			player.velocity.y -= player.gravity/60.0
			player.move_and_slide()
		check(player.is_on_floor(), '%s takeoff grounded' % source.name)
		player.velocity = Vector3(0,player.jump_force,-player.run_speed)
		var landed := false
		for frame in range(65):
			await get_tree().physics_frame
			player.velocity.y -= player.gravity/60.0
			var remaining := player.position.z - destination.z
			var stopping_distance: float = player.velocity.z * player.velocity.z / (2.0 * player.air_acceleration)
			if remaining <= stopping_distance + 0.05:
				player.velocity.z = move_toward(player.velocity.z, 0.0, player.air_acceleration / 60.0)
			player.move_and_slide()
			if player.is_on_floor():
				for c in player.get_slide_collision_count():
					if player.get_slide_collision(c).get_collider() == target:
						landed = true
			if landed:
				break
		print('  jump endpoint: ',player.position)
		check(landed, '%02d -> %02d reachable with one running jump' % [i+1,i+2])
	await frames(2)
	check(level.finished and level.highest == 10, 'Landing on platform 10 completes the course')
	Input.action_press('restart_test')
	await frames(2)
	Input.action_release('restart_test')
	player.move_and_slide()
	await frames(1)
	check(not level.finished and level.highest == 1 and level.falls == 0, 'R restarts course progress and timer')
	player.reset_to_spawn(Vector3(30,-8.2,0))
	await frames(3)
	check(level.falls == 1 and player.position.distance_to(level.get_node('SpawnPosition').position) < 0.1, 'Falling below -8 m resets to start and counts fall')
	player.reset_to_spawn(Vector3(0,0.4,0.9))
	for i in range(25):
		await get_tree().physics_frame
		player.velocity.y -= player.gravity/60.0
		player.move_and_slide()
	check(player.is_on_floor(), 'Spawn lands safely on platform 01')
	print('JUMP LEVEL TESTS: %s' % ('ALL PASSED' if failures.is_empty() else str(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)


