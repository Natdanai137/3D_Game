extends Node

var failures: Array[String] = []
var level: Node3D
var player
var space: PhysicsDirectSpaceState3D
const DT := 1.0/60.0

func check(ok: bool, message: String) -> void:
	print(('PASS: ' if ok else 'FAIL: ')+message)
	if not ok:
		failures.append(message)

func frame() -> void:
	await get_tree().physics_frame
	player.update_jump_state(DT)
	if not player.is_on_floor():
		player.velocity.y -= player.gravity*DT
	player.move_and_slide()

func settle(position: Vector3) -> void:
	player.reset_to_spawn(position)
	player.velocity.y = -0.1
	player.move_and_slide()
	for i in range(25):
		await frame()
	await get_tree().physics_frame

func ground(x: float,z: float) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x,80,z),Vector3(x,-25,z),1,[player.get_rid()])
	return space.intersect_ray(query)

func _ready() -> void:
	level = load('res://Scenes/floating_town.tscn').instantiate()
	add_child(level)
	player = level.get_node('Player')
	player.set_physics_process(false)
	await get_tree().physics_frame
	space = level.get_world_3d().direct_space_state
	var checkpoints: Node3D = level.get_node('Checkpoints')
	check(checkpoints.get_child_count()==3,'Three Uncle Oli checkpoints load')
	check(level.find_children('*','Label3D',true,false).is_empty(),'No text floats above platforms')
	for cp in checkpoints.get_children():
		check(cp.get_node('UncleOli/Asset')!=null,'UncleOli model is present at '+str(cp.name))
	await settle(level.respawn_position)
	check(player.is_on_floor(),'Start checkpoint has a safe landing surface')
	check(player.jump_limit==3,'Aof has three jumps per landing')
	for jump in range(3):
		player.buffered_jump = player.jump_buffer
		check(player.try_buffered_jump(),'Jump %d fires' % (jump+1))
		for i in range(18):
			await frame()
		check(not player.is_on_floor(),'Jump %d remains airborne' % (jump+1))
	player.buffered_jump = player.jump_buffer
	check(not player.try_buffered_jump(),'Fourth consecutive jump is blocked')
	player.buffered_jump = 0.0
	for i in range(100):
		await frame()
	check(player.is_on_floor() and player.jumps_used==0,'Landing restores all three jumps')
	player.reset_to_spawn(checkpoints.get_child(1).get_node('Spawn').global_position+Vector3.UP)
	player.move_and_slide()
	for i in range(4):
		await frame()
	check(level.active_checkpoint==0,'Passing a checkpoint in midair does not save')
	await settle(checkpoints.get_child(1).get_node('Spawn').global_position)
	check(level.active_checkpoint==1,'Standing by Uncle Oli saves checkpoint 2')
	await settle(checkpoints.get_child(2).get_node('Spawn').global_position)
	check(level.active_checkpoint==2,'Standing by Uncle Oli saves checkpoint 3')
	check(not checkpoints.get_child(1).active and checkpoints.get_child(2).active,'Only the latest checkpoint ring is active')
	await settle(checkpoints.get_child(0).get_node('Spawn').global_position)
	check(level.active_checkpoint==2,'Returning to an older checkpoint preserves latest progress')
	player.reset_to_spawn(Vector3(40,-12.5,0))
	player.velocity=Vector3(2,-20,3)
	player.jumps_used=3
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(level.falls==1 and player.position.distance_to(level.respawn_position)<0.02,'Falling below the world respawns at latest checkpoint')
	check(player.velocity==Vector3.ZERO and player.jumps_used==0,'Respawn resets velocity and restores three jumps')
	var camera: Node3D = player.get_node('Gimbal')
	check(camera.global_position.distance_to(level.respawn_position+Vector3.UP*1.25)<0.1,'Camera returns with player')
	level.set_physics_process(false)
	var route: Array[Node] = level.get_node('Platforms').get_children()
	check(route.size()==18,'Floating Town has 18 playable platforms')
	for i in range(route.size()-1):
		var source: StaticBody3D = route[i]
		var target: StaticBody3D = route[i+1]
		var origin: Vector3 = source.get_meta('landing')
		var destination: Vector3 = target.get_meta('landing')
		var footprint: Vector2 = source.get_meta('footprint')
		var hit := {}
		for margin in [.35,.6,.85,1.1,1.4]:
			hit = ground(destination.x,origin.z-footprint.y*.5+margin)
			if not hit.is_empty() and hit.collider==source and hit.normal.y>.76:
				break
		if hit.is_empty() or hit.collider!=source:
			check(false,'Takeoff surface on '+str(source.name))
			continue
		await settle(hit.position+Vector3.UP*.03)
		player.velocity.z=-player.run_speed
		player.buffered_jump=player.jump_buffer
		player.try_buffered_jump()
		var landed := false
		for k in range(135):
			await get_tree().physics_frame
			player.update_jump_state(DT)
			var jumped := false
			if not player.is_on_floor() and player.velocity.y<.4 and player.jumps_used<player.jump_limit:
				player.buffered_jump=player.jump_buffer
				jumped=player.try_buffered_jump()
			if not jumped and not player.is_on_floor():
				player.velocity.y-=player.gravity*DT
			var remaining: float = player.position.z-destination.z
			var stop: float = player.velocity.z*player.velocity.z/(2.0*player.air_acceleration)
			var desired_speed: float = 0.0 if remaining <= stop+.05 else -player.run_speed
			player.velocity.z=move_toward(player.velocity.z,desired_speed,player.air_acceleration*DT)
			player.move_and_slide()
			if player.is_on_floor():
				for c in player.get_slide_collision_count():
					if player.get_slide_collision(c).get_collider()==target:
						landed=true
			if landed:
				break
		check(landed,'%02d -> %02d reachable with up to three jumps' % [i+1,i+2])
		if not landed:
			print('Failed endpoint ',player.position,' target ',destination)
	level.set_physics_process(true)
	await get_tree().physics_frame
	check(level.finished,'Final floating street completes Floating Town')
	print('FLOATING TOWN TESTS: %s' % ('ALL PASSED' if failures.is_empty() else str(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)
