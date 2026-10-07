extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred('run')
func check(value: bool, description: String) -> void:
	if not value:
		failures += 1
		push_error(description)
	else:
		print('PASS: '+description)
func settle() -> void:
	await process_frame
	await process_frame
	await process_frame
func run() -> void:
	check(change_scene_to_file('res://Scenes/main_menu.tscn') == OK, 'Menu loads')
	await settle()
	var ui = current_scene.get_node('MenuCanvas/MainMenuUI')
	check(ui.play_button.has_focus(), 'Start has keyboard focus')
	check(get_nodes_in_group('Player').is_empty(), 'Backdrop has no playable character')
	check(current_scene.has_node('Backdrop/Aof'), 'Aof model is in backdrop')
	ui.controls_button.pressed.emit()
	await settle()
	check(ui.controls_dialog.visible, 'Controls dialog opens')
	ui.controls_dialog.hide()
	for button in [ui.play_button,ui.controls_button,ui.quit_button]:
		check(Rect2(Vector2.ZERO,ui.get_viewport_rect().size).encloses(button.get_global_rect()), 'Button fits viewport: '+button.name)
	ui.play_button.pressed.emit()
	await settle()
	check(current_scene.name == 'FloatingTown', 'Start opens Floating Town')
	var buttons = current_scene.find_children('MainMenuButton','Button',true,false)
	check(buttons.size() == 1, 'Town has return-to-menu button')
	if not buttons.is_empty():
		buttons[0].pressed.emit()
		await settle()
		check(current_scene.name == 'MainMenu', 'Return opens menu')
		check(get_nodes_in_group('Player').is_empty(), 'Gameplay scene is freed')
	print('MENU TEST: %d failures' % failures)
	current_scene.queue_free()
	await settle()
	quit(1 if failures else 0)


