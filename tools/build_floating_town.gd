extends SceneTree

const ASSETS := 'res://Assets/assets model 3d/'
# Asset, largest footprint, yaw, center X, landing height, edge gap.
const ROUTE := [
	['Street',14.0,0.0,0.0,0.0,0.0],
	['Sports Car1',4.2,0.0,0.0,1.0,1.3],
	['table2',3.2,0.0,0.4,2.0,1.6],
	['Cargo Train',5.0,90.0,0.0,3.1,2.0],
	['Large Building',5.0,0.0,0.0,4.3,2.0],
	['Street',14.0,0.0,0.0,5.7,1.8],
	['sofa1',3.8,0.0,0.4,6.7,1.6],
	['Sports Car1',4.6,0.0,0.0,7.9,1.7],
	['table2',3.5,0.0,-0.3,9.1,2.0],
	['Cargo Train',5.0,90.0,0.0,10.3,2.0],
	['Large Building',5.5,0.0,0.0,11.6,2.0],
	['Street',14.0,0.0,0.0,13.0,1.8],
	['table2',3.5,0.0,0.0,14.2,2.0],
	['Sports Car1',5.0,0.0,0.0,15.5,2.1],
	['table1',4.0,90.0,0.0,16.8,2.1],
	['Cargo Train',5.5,90.0,0.0,18.1,2.2],
	['Large Building',6.0,0.0,0.0,19.4,2.3],
	['Street',14.0,0.0,0.0,20.8,2.0],
]
var level: Node3D
var platforms: Node3D
var checkpoints: Node3D
var manifest: Array = []

func _initialize() -> void:
	call_deferred('build')

func add(node: Node, parent: Node) -> void:
	parent.add_child(node)
	node.owner = level

func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.85
	if glow:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = 0.8
	return result

func bounds_of(node: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	for mesh in node.find_children('*','MeshInstance3D',true,false):
		if mesh.mesh:
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
	return bounds

func top_at(faces: PackedVector3Array) -> float:
	var best := -INF
	for i in range(0,faces.size(),3):
		var hit = Geometry3D.ray_intersects_triangle(Vector3(0,100,0),Vector3.DOWN,faces[i],faces[i+1],faces[i+2])
		if hit != null:
			best = maxf(best,hit.y)
	return best

func box(parent: Node3D, name: String, size: Vector3, position: Vector3, color: Color, solid: bool = false) -> void:
	var visual := MeshInstance3D.new()
	visual.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.material_override = material(color)
	add(visual,parent)
	if solid:
		var collision := CollisionShape3D.new()
		collision.name = name+'Collision'
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		collision.position = position
		add(collision,parent)

func normalized_asset(path: String, parent: Node3D, size: float, yaw: float = 0.0, by_height: bool = false) -> Node3D:
	var asset = load(path).instantiate()
	asset.name = 'Asset'
	add(asset,parent)
	asset.rotation.y += deg_to_rad(yaw)
	var bounds := bounds_of(asset)
	var factor := size / (bounds.size.y if by_height else maxf(bounds.size.x,bounds.size.z))
	asset.scale *= factor
	bounds = bounds_of(asset)
	# Parent is at the origin while normalizing; source origins can be far off.
	asset.position -= Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	return asset

func collision_faces(asset: Node3D, body: Node3D) -> PackedVector3Array:
	var faces := PackedVector3Array()
	for mesh in asset.find_children('*','MeshInstance3D',true,false):
		if mesh.mesh:
			var transform: Transform3D = body.global_transform.affine_inverse()*mesh.global_transform
			for vertex in mesh.mesh.get_faces():
				faces.append(transform*vertex)
	return faces

func decorate_street(body: StaticBody3D, height: float, variant: int) -> void:
	box(body,'FloatingStone',Vector3(13,1.6,9),Vector3(0,height-1.1,0),Color(.29,.35,.39))
	box(body,'Underside',Vector3(11,1.5,7),Vector3(0,height-2.5,0),Color(.20,.25,.29))
	box(body,'Road',Vector3(4,.03,10),Vector3(0,height+.015,0),Color(.12,.17,.20))
	for z in [-3.0,0.0,3.0]:
		box(body,'LaneMark',Vector3(.13,.015,1.0),Vector3(0,height+.035,z),Color(.95,.79,.42))
	for side in [-1,1]:
		box(body,'Rail',Vector3(.12,.65,8),Vector3(side*6.7,height+.4,0),Color(.35,.58,.57),true)
		var holder := Node3D.new()
		holder.name = 'HouseSide%d' % side
		add(holder,body)
		var house := normalized_asset(ASSETS+'House1.glb',holder,4.4,180.0 if side<0 else 0.0)
		house.position += Vector3(side*4.6,height,-1.3 if variant%2==0 else -1.8)
		var faces := collision_faces(house,body)
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		var collision := CollisionShape3D.new()
		collision.name = 'HouseCollision'
		collision.shape = shape
		add(collision,body)

func checkpoint_for(body: StaticBody3D, height: float, index: int) -> void:
	var checkpoint := Area3D.new()
	checkpoint.name = 'OliCheckpoint%d' % (index+1)
	add(checkpoint,checkpoints)
	checkpoint.position = Vector3(body.position.x,height,body.position.z+1.2)
	var trigger := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.8,2.4,3.8)
	trigger.shape = shape
	trigger.position.y = 1.15
	add(trigger,checkpoint)
	var spawn := Marker3D.new()
	spawn.name = 'Spawn'
	spawn.position.y = .12
	add(spawn,checkpoint)
	var ring := MeshInstance3D.new()
	ring.name = 'Ring'
	var torus := TorusMesh.new()
	torus.inner_radius = .85
	torus.outer_radius = 1.1
	torus.rings = 32
	torus.ring_segments = 12
	ring.mesh = torus
	ring.position.y = .13
	ring.material_override = material(Color(1,.68,.2),true)
	add(ring,checkpoint)
	var npc := StaticBody3D.new()
	npc.name = 'UncleOli'
	add(npc,checkpoint)
	# Temporarily normalize at world origin to avoid inherited placement offsets.
	var saved := checkpoint.position
	checkpoint.position = Vector3.ZERO
	var oli := normalized_asset('res://Assets/model/UncleOli/UncleOli.glb',npc,1.7,0.0,true)
	checkpoint.position = saved
	npc.position = Vector3(2.15,0,-.15)
	var npc_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .45
	capsule.height = 1.7
	npc_shape.shape = capsule
	npc_shape.position.y = .85
	add(npc_shape,npc)
	checkpoint.set_script(load('res://Scripts/OliCheckpoint.gd'))
	checkpoint.set('checkpoint_index',index)

func build() -> void:
	level = Node3D.new()
	level.name = 'FloatingTown'
	root.add_child(level)
	level.set_script(load('res://Scripts/FloatingTown.gd'))
	platforms = Node3D.new()
	platforms.name = 'Platforms'
	add(platforms,level)
	checkpoints = Node3D.new()
	checkpoints.name = 'Checkpoints'
	add(checkpoints,level)
	var previous_front := 0.0
	var checkpoint_index := 0
	for i in ROUTE.size():
		var entry: Array = ROUTE[i]
		var body := StaticBody3D.new()
		body.name = 'Platform%02d' % (i+1)
		add(body,platforms)
		var footprint := Vector2(14,10)
		if entry[0] == 'Street':
			box(body,'StreetDeck',Vector3(14,.7,10),Vector3(0,entry[4]-.35,0),Color(.64,.66,.59),true)
			decorate_street(body,entry[4],i)
		else:
			var asset := normalized_asset(ASSETS+entry[0]+'.glb',body,entry[1],entry[2])
			var faces := collision_faces(asset,body)
			var center_top := top_at(faces)
			assert(is_finite(center_top))
			var shift: float = entry[4]-center_top
			asset.position.y += shift
			for v in faces.size():
				faces[v].y += shift
			var collision := CollisionShape3D.new()
			var shape := ConcavePolygonShape3D.new()
			shape.set_faces(faces)
			collision.shape = shape
			add(collision,body)
			var bounds := bounds_of(asset)
			footprint = Vector2(bounds.size.x,bounds.size.z)
		var center_z: float = 0.0 if i==0 else previous_front-entry[5]-footprint.y*.5
		body.position = Vector3(entry[3],0,center_z)
		previous_front = center_z-footprint.y*.5
		var landing := Vector3(entry[3],entry[4],center_z)
		body.set_meta('landing',landing)
		body.set_meta('footprint',footprint)
		body.set_meta('asset',entry[0])
		if i in [0,5,11]:
			checkpoint_for(body,entry[4],checkpoint_index)
			checkpoint_index += 1
		if i == ROUTE.size()-1:
			body.set_meta('zone_exit',true)
			box(body,'PortalLeft',Vector3(.3,3.2,.4),Vector3(-1.7,entry[4]+1.6,-2.7),Color(.23,.65,.76))
			box(body,'PortalRight',Vector3(.3,3.2,.4),Vector3(1.7,entry[4]+1.6,-2.7),Color(.23,.65,.76))
			box(body,'PortalTop',Vector3(3.7,.3,.4),Vector3(0,entry[4]+3.1,-2.7),Color(.23,.65,.76))
		manifest.append({'number':i+1,'asset':entry[0],'landing':[landing.x,landing.y,landing.z],'gap':entry[5],'footprint':[footprint.x,footprint.y]})
	var player = load('res://Scenes/player.tscn').instantiate()
	player.name = 'Player'
	player.position = checkpoints.get_child(0).get_node('Spawn').global_position
	add(player,level)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(.15,.46,.69)
	sky_material.sky_horizon_color = Color(.76,.88,.96)
	sky_material.ground_horizon_color = Color(.76,.88,.96)
	sky_material.ground_bottom_color = Color(.36,.53,.65)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(.82,.9,1)
	environment.ambient_light_energy = .7
	world.environment = environment
	add(world,level)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40,-25,0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add(sun,level)
	var skyline := Node3D.new()
	skyline.name = 'DistantCity'
	add(skyline,level)
	for i in range(8):
		var holder := Node3D.new()
		add(holder,skyline)
		var model := normalized_asset(ASSETS+('House1.glb' if i%2==0 else 'Large Building.glb'),holder,6+i%3)
		holder.position = Vector3((-1 if i%2==0 else 1)*(19+i%3*3),2+i*2,-10-i*12)
	var packed := PackedScene.new()
	assert(packed.pack(level)==OK)
	assert(ResourceSaver.save(packed,'res://Scenes/floating_town.tscn')==OK)
	var output := FileAccess.open('res://tests/floating_town_layout.json',FileAccess.WRITE)
	output.store_string(JSON.stringify(manifest,'\t'))
	print('Built Floating Town: ',ROUTE.size(),' platforms, ',checkpoint_index,' Uncle Oli checkpoints, no platform text.')
	level.free()
	quit()
