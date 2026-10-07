extends SceneTree
var level: Node3D

func _initialize() -> void:
	call_deferred('build')

func own(node: Node) -> void:
	if node.owner == null:
		node.owner = level
	for child in node.get_children():
		own(child)

func build() -> void:
	level = Node3D.new()
	level.name = 'MainMenu'
	root.add_child(level)
	var source = load('res://Scenes/floating_town.tscn').instantiate()
	var backdrop := Node3D.new()
	backdrop.name = 'Backdrop'
	level.add_child(backdrop)
	backdrop.owner = level
	var street = source.get_node('Platforms/Platform01').duplicate()
	street.name = 'FloatingStreet'
	backdrop.add_child(street)
	own(street)
	var skyline = source.get_node('DistantCity').duplicate()
	backdrop.add_child(skyline)
	own(skyline)
	for node in source.get_children():
		if node is WorldEnvironment or node is DirectionalLight3D:
			var clone = node.duplicate()
			level.add_child(clone)
			own(clone)
	var actor = load('res://Assets/model/Aof/AofPlayer.tscn').instantiate()
	actor.name = 'Aof'
	actor.position = Vector3(.25,.025,.2)
	actor.rotation_degrees.y = -12.0
	backdrop.add_child(actor)
	actor.owner = level
	var camera := Camera3D.new()
	camera.name = 'MenuCamera'
	camera.position = Vector3(0,2.4,4.5)
	level.add_child(camera)
	camera.owner = level
	camera.look_at(Vector3(0,.95,0))
	camera.h_offset = -1.35
	camera.fov = 40.0
	camera.current = true
	var canvas := CanvasLayer.new()
	canvas.name = 'MenuCanvas'
	level.add_child(canvas)
	canvas.owner = level
	var ui = load('res://Scenes/main_menu_ui.tscn').instantiate()
	canvas.add_child(ui)
	ui.owner = level
	var packed := PackedScene.new()
	assert(packed.pack(level)==OK)
	assert(ResourceSaver.save(packed,'res://Scenes/main_menu.tscn')==OK)
	source.free()
	level.free()
	print('Built main menu with Aof, floating-city backdrop and Thai controls.')
	quit()
