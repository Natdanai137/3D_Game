extends Node3D

@onready var player = $Player
@onready var spawn: Marker3D = $SpawnPosition
var falls: int = 0
var elapsed: float = 0.0
var highest: int = 1
var finished: bool = false
var status: Label
var hint: Label
var previous_grounded: bool = false
var previous_position := Vector3.ZERO
var jump_origin := Vector3.ZERO
var jump_peak: float = 0.0
var measuring_jump: bool = false
var last_jump_height: float = 0.0
var last_jump_distance: float = 0.0

func _ready() -> void:
	previous_position = player.global_position
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(20,20)
	panel.custom_minimum_size = Vector2(380,0)
	canvas.add_child(panel)
	var padding := MarginContainer.new()
	for side in ['left','top','right','bottom']:
		padding.add_theme_constant_override('margin_'+side,16)
	panel.add_child(padding)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override('separation',8)
	padding.add_child(layout)
	var title := Label.new()
	title.text = 'JUST GO UP!! / JUMP TEST'
	title.add_theme_font_size_override('font_size',22)
	title.modulate = Color(1,0.75,0.35)
	layout.add_child(title)
	status = Label.new()
	status.add_theme_font_size_override('font_size',18)
	layout.add_child(status)
	hint = Label.new()
	hint.text = 'WASD: walk   Shift: run   Space: jump\nMouse: camera   R: restart\nEsc: release cursor   Click: resume\nFollow 01 -> 10. Release WASD to brake before landing.\nFall below -8 m to restart.'
	layout.add_child(hint)
	var restart := InputEventKey.new()
	restart.physical_keycode = KEY_R
	if not InputMap.has_action('restart_test'):
		InputMap.add_action('restart_test')
		InputMap.action_add_event('restart_test',restart)

func _physics_process(delta: float) -> void:
	if not finished:
		elapsed += delta
	if player.global_position.y < -8.0:
		falls += 1
		player.reset_to_spawn(spawn.global_position)
		measuring_jump = false
		previous_grounded = false
	if Input.is_action_just_pressed('restart_test'):
		falls = 0
		elapsed = 0.0
		highest = 1
		finished = false
		last_jump_height = 0.0
		last_jump_distance = 0.0
		measuring_jump = false
		previous_grounded = false
		player.reset_to_spawn(spawn.global_position)
		previous_position = player.global_position
		return
	var grounded: bool = player.is_on_floor()
	if previous_grounded and not grounded and player.velocity.y > 0.0:
		jump_origin = previous_position
		jump_peak = player.global_position.y
		measuring_jump = true
	if measuring_jump:
		jump_peak = maxf(jump_peak,player.global_position.y)
		if grounded:
			last_jump_height = maxf(0.0,jump_peak-jump_origin.y)
			last_jump_distance = Vector2(player.global_position.x-jump_origin.x,player.global_position.z-jump_origin.z).length()
			measuring_jump = false
	previous_grounded = grounded
	previous_position = player.global_position
	if grounded:
		for i in player.get_slide_collision_count():
			var collider = player.get_slide_collision(i).get_collider()
			if collider is StaticBody3D and collider.get_parent() == $Platforms:
				var number := int(str(collider.name).trim_prefix('Platform'))
				highest = maxi(highest,number)
				if number == 10:
					finished = true
	status.text = 'Platform %02d / 10    Height %.2f m\nTime %.1f s    Falls %d\nLast jump: +%.2f m high / %.2f m across%s' % [highest,player.global_position.y,elapsed,falls,last_jump_height,last_jump_distance,'\nCOMPLETE! Press R to try again.' if finished else '']
