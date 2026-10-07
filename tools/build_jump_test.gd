extends SceneTree

const ASSETS := 'res://Assets/assets model 3d/'
const DATA := [
	['table2',4.0,0.0,0.0,0.0,0.0],
	['table1',2.8,90.0,0.0,0.30,0.65],
	['table2',2.8,0.0,0.0,0.65,0.85],
	['sofa1',3.2,0.0,0.5,1.05,0.75],
	['table2',2.8,0.0,0.5,1.55,0.90],
	['Sports Car1',4.2,90.0,0.0,2.00,1.05],
	['table1',3.0,90.0,0.0,2.60,1.10],
	['Cargo Train',5.0,0.0,-0.5,3.15,1.30],
	['table2',2.6,0.0,-0.5,3.80,1.45],
	['Large Building',3.2,0.0,0.0,4.30,1.40],
]
var level: Node3D
var platforms: Node3D
var manifest: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred('build')

func owned(node: Node, parent: Node) -> void:
	parent.add_child(node)
	node.owner = level

func mesh_bounds(node: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	for mesh in node.find_children('*','MeshInstance3D',true,false):
		if mesh.mesh:
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
	return bounds

func top_at(faces: PackedVector3Array, x: float, z: float) -> float:
	var best := -INF
	for i in range(0,faces.size(),3):
		var hit = Geometry3D.ray_intersects_triangle(Vector3(x,100,z),Vector3.DOWN,faces[i],faces[i+1],faces[i+2])
		if hit != null:
			best = maxf(best,hit.y)
	return best

func build() -> void:
	level = Node3D.new()
	level.name = 'JumpTestLevel'
	root.add_child(level)
	level.set_script(load('res://Scripts/JumpTestLevel.gd'))
	platforms = Node3D.new()
	platforms.name = 'Platforms'
	owned(platforms,level)
	var previous_front := 0.0
	for index in DATA.size():
		var entry: Array = DATA[index]
		var body := StaticBody3D.new()
		body.name = 'Platform%02d' % (index+1)
		owned(body,platforms)
		var model = load(ASSETS+entry[0]+'.glb').instantiate()
		model.name = 'Asset'
		body.add_child(model)
		model.owner = level
		model.rotation.y += deg_to_rad(entry[2])
		var bounds := mesh_bounds(model)
		var factor: float = entry[1] / maxf(bounds.size.x,bounds.size.z)
		model.scale *= factor
		bounds = mesh_bounds(model)
		model.position -= Vector3(bounds.get_center().x,0,bounds.get_center().z)
		var faces := PackedVector3Array()
		for mesh in model.find_children('*','MeshInstance3D',true,false):
			if mesh.mesh:
				var transform: Transform3D = body.global_transform.affine_inverse() * mesh.global_transform
				for vertex in mesh.mesh.get_faces():
					faces.append(transform * vertex)
		var landing_y := top_at(faces,0,0)
		assert(is_finite(landing_y), 'No walkable center surface: '+entry[0])
		var shift: float = entry[4] - landing_y
		model.position.y += shift
		for i in faces.size():
			faces[i].y += shift
		var collision := CollisionShape3D.new()
		collision.name = 'AssetCollision'
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		collision.shape = shape
		owned(collision,body)
		bounds = mesh_bounds(model)
		var center_z: float = 0.0 if index == 0 else previous_front - entry[5] - bounds.size.z*0.5
		body.position = Vector3(entry[3],0,center_z)
		previous_front = center_z - bounds.size.z*0.5
		var surface := Vector3(entry[3],entry[4],center_z)
		body.set_meta('landing',surface)
		body.set_meta('asset',entry[0])
		body.set_meta('gap',entry[5])
		body.set_meta('footprint',Vector2(bounds.size.x,bounds.size.z))
		var record := {'number':index+1,'asset':entry[0],'landing':[surface.x,surface.y,surface.z],'gap':entry[5],'footprint':[bounds.size.x,bounds.size.z]}
		manifest.append(record)
		print(record)
	var spawn := Marker3D.new()
	spawn.name = 'SpawnPosition'
	spawn.position = Vector3(0,0.12,0.9)
	owned(spawn,level)
	var player = load('res://Scenes/player.tscn').instantiate()
	player.name = 'Player'
	player.position = spawn.position
	owned(player,level)
	var world := WorldEnvironment.new()
	world.name = 'WorldEnvironment'
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.10,0.35,0.58)
	sky_material.sky_horizon_color = Color(0.73,0.86,0.94)
	sky_material.ground_bottom_color = Color(0.15,0.29,0.40)
	sky_material.ground_horizon_color = Color(0.73,0.86,0.94)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.81,0.89,1)
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	owned(world,level)
	var sun := DirectionalLight3D.new()
	sun.name = 'Sun'
	sun.rotation_degrees = Vector3(-45,-30,0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	owned(sun,level)
	var packed := PackedScene.new()
	var result := packed.pack(level)
	assert(result == OK)
	assert(ResourceSaver.save(packed,'res://Scenes/jump_test.tscn') == OK)
	var output := FileAccess.open('res://tests/jump_test_layout.json',FileAccess.WRITE)
	output.store_string(JSON.stringify(manifest,'\t'))
	level.free()
	quit()


