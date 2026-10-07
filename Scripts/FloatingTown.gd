extends Node3D

@export var death_height: float = -12.0
@onready var player = $Player
@onready var checkpoints: Node3D = $Checkpoints
var active_checkpoint: int = 0
var respawn_position := Vector3.ZERO
var falls: int = 0
var elapsed: float = 0.0
var finished: bool = false
var status: Label
var notice: Label
var notice_time: float = 0.0

func _ready() -> void:
	respawn_position = checkpoints.get_child(0).get_node('Spawn').global_position
	checkpoints.get_child(0).set_active(true)
	var canvas := CanvasLayer.new()
	canvas.name = 'HUD'
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(20,20)
	canvas.add_child(panel)
	var padding := MarginContainer.new()
	for side in ['left','top','right','bottom']:
		padding.add_theme_constant_override('margin_'+side,14)
	panel.add_child(padding)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override('separation',8)
	padding.add_child(rows)
	var title := Label.new()
	title.text = 'JUST GO UP!! / FLOATING TOWN'
	title.add_theme_font_size_override('font_size',22)
	title.modulate = Color(1,0.76,0.35)
	rows.add_child(title)
	status = Label.new()
	rows.add_child(status)
	notice = Label.new()
	notice.modulate = Color(0.35,1,0.7)
	rows.add_child(notice)
	var hint := Label.new()
	hint.text = 'WASD: walk / Shift: run / Space: up to 3 jumps\nMeet Uncle Oli on the glowing rings to save.\nR: return to checkpoint / Esc: release mouse'
	if OS.has_feature('web'):
		hint.text += '\nClick the scene to control / Esc: release mouse'
	rows.add_child(hint)
	var menu_button := Button.new()
	menu_button.name = 'MainMenuButton'
	menu_button.text = 'เมนูหลัก'
	menu_button.pressed.connect(func(): get_tree().change_scene_to_file('res://Scenes/main_menu.tscn'))
	rows.add_child(menu_button)
	if not InputMap.has_action('return_checkpoint'):
		InputMap.add_action('return_checkpoint')
		var key := InputEventKey.new()
		key.physical_keycode = KEY_R
		InputMap.action_add_event('return_checkpoint',key)

func activate_checkpoint(checkpoint: Area3D) -> void:
	if checkpoint.checkpoint_index <= active_checkpoint:
		return
	checkpoints.get_child(active_checkpoint).set_active(false)
	active_checkpoint = checkpoint.checkpoint_index
	respawn_position = checkpoint.get_node('Spawn').global_position
	checkpoint.set_active(true)
	notice.text = 'Checkpoint %d saved!' % (active_checkpoint + 1)
	notice_time = 4.0

func respawn(count_fall: bool = true) -> void:
	if count_fall:
		falls += 1
	player.reset_to_spawn(respawn_position)

func _physics_process(delta: float) -> void:
	if not finished:
		elapsed += delta
	if player.global_position.y < death_height:
		respawn()
		update_hud()
		return
	if Input.is_action_just_pressed('return_checkpoint'):
		respawn(false)
		update_hud()
		return
	if player.is_on_floor():
		for i in player.get_slide_collision_count():
			var collider = player.get_slide_collision(i).get_collider()
			if collider is StaticBody3D and collider.has_meta('zone_exit'):
				finished = true
	notice_time = maxf(0.0,notice_time-delta)
	notice.visible = notice_time > 0.0
	update_hud()

func update_hud() -> void:
	status.text = 'Height %.1f m / Time %.1f s / Falls %d\nCheckpoint %d / %d / Jumps left %d%s' % [player.global_position.y,elapsed,falls,active_checkpoint+1,checkpoints.get_child_count(),player.jump_limit-player.jumps_used,'\nFloating Town complete! Cloud Sea is next.' if finished else '']

