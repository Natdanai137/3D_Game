extends SceneTree
func _initialize() -> void:
	call_deferred('inspect')
func inspect() -> void:
	var model = load('res://Assets/model/Aof/Aof_Rigged.glb').instantiate()
	root.add_child(model)
	model.print_tree_pretty()
	for node in model.find_children('*','AnimationPlayer',true,false):
		print('CLIPS: ',node.get_animation_list())
	for node in model.find_children('*','Skeleton3D',true,false):
		print('BONES: ',node.get_bone_count())
	for node in model.find_children('*','MeshInstance3D',true,false):
		print('MESH SKIN: ',node.skin,' SKELETON: ',node.skeleton)
	model.free()
	quit()
