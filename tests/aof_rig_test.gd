extends Node

var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	print(('PASS: ' if ok else 'FAIL: ') + message)
	if not ok:
		failures.append(message)

func skin_vertices(mesh: MeshInstance3D, skeleton: Skeleton3D, arrays: Array) -> PackedVector3Array:
	skeleton.force_update_all_bone_transforms()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var transforms: Array[Transform3D] = []
	for i in mesh.skin.get_bind_count():
		var bone := mesh.skin.get_bind_bone(i)
		if bone < 0:
			bone = skeleton.find_bone(mesh.skin.get_bind_name(i))
		transforms.append(skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(i))
	var result := PackedVector3Array()
	result.resize(vertices.size())
	var stride := weights.size()/vertices.size()
	for i in vertices.size():
		var position := Vector3.ZERO
		for j in stride:
			var index := i*stride+j
			position += transforms[joints[index]]*vertices[i]*weights[index]
		result[i] = position
	return result

func _ready() -> void:
	var player = load('res://Scenes/player.tscn').instantiate()
	add_child(player)
	player.set_physics_process(false)
	await get_tree().process_frame
	var visual = player.get_node('CharacterModel')
	var skeleton: Skeleton3D = visual.get_node('Rig/Skeleton3D')
	var mesh: MeshInstance3D = skeleton.get_node('AofMesh')
	var animation: AnimationPlayer = visual.get_node('Rig/AnimationPlayer')
	check(skeleton.get_bone_count() == 22, 'Replacement Aof has a 22-bone skeleton')
	check(mesh.skin != null and mesh.skin.get_bind_count() == 22, 'Mesh is bound to all skeleton bones')
	check(mesh.get_aabb().size.y > 1.79 and mesh.get_aabb().size.y < 1.81, 'Aof height matches 1.8 m player capsule')
	var array = mesh.mesh.surface_get_arrays(0)
	var weights: PackedFloat32Array = array[Mesh.ARRAY_WEIGHTS]
	var good := true
	for i in range(0,weights.size(),4):
		var total := 0.0
		for j in range(4):
			good = good and is_finite(weights[i+j]) and weights[i+j] >= 0.0
			total += weights[i+j]
		good = good and absf(total-1.0) < 0.0001
	check(good and weights.size() > 0, 'Every mesh vertex has finite normalized skin weights')
	animation.stop()
	skeleton.reset_bone_poses()
	var neutral := skin_vertices(mesh,skeleton,array)
	var source: PackedVector3Array = array[Mesh.ARRAY_VERTEX]
	var error := 0.0
	for i in neutral.size():
		error = maxf(error,neutral[i].distance_to(source[i]))
	check(error < 0.0001, 'Rest skin preserves source geometry (no bind offset)')
	for state in [['Idle',0.0,true,0.0,false],['Walk',3.5,true,0.0,false],['Run',6.0,true,0.0,true],['Jump',3.0,false,4.0,false],['Fall',3.0,false,-4.0,false]]:
		visual.animate(1.0/60.0,state[1],state[2],state[3],state[4])
		check(animation.current_animation == state[0], '%s selected by movement state' % state[0])
		animation.advance(0.20)
		await get_tree().process_frame
		var positions := skin_vertices(mesh,skeleton,array)
		var changed := 0
		var finite := true
		var maximum := 0.0
		for i in positions.size():
			finite = finite and positions[i].is_finite()
			var distance := positions[i].distance_to(neutral[i])
			maximum = maxf(maximum,distance)
			if distance > 0.001:
				changed += 1
		check(finite and maximum < 1.0, '%s skin deforms within valid body bounds' % state[0])
		check(changed > 100, '%s visibly animates the skinned mesh' % state[0])
	visual.animate(1.0/60.0,0,true,0,false)
	check(animation.current_animation == 'Idle','Stopping movement returns to Idle')
	print('AOF RIG TESTS: %s' % ('ALL PASSED' if failures.is_empty() else str(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)
