extends Node3D

@export var mouse_sensitivity: float = 0.18
@export var follow_speed: float = 18.0
@export var target_height: float = 1.25
@onready var player: CharacterBody3D = get_parent()
@onready var arm: SpringArm3D = $SpringArm3D

func _ready() -> void:
	top_level = true
	arm.add_excluded_object(player.get_rid())
	rotation_degrees.x = -15.0
	snap_to_player()
	if not OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func snap_to_player() -> void:
	global_position = player.global_position + Vector3.UP * target_height

func _process(delta: float) -> void:
	var target := player.global_position + Vector3.UP * target_height
	if global_position.distance_to(target) > 10.0:
		global_position = target
	else:
		global_position = global_position.lerp(target, 1.0 - exp(-follow_speed * delta))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation_degrees.x = clampf(rotation_degrees.x - event.relative.y * mouse_sensitivity, -65.0, 45.0)
		rotation_degrees.y = wrapf(rotation_degrees.y - event.relative.x * mouse_sensitivity, -180.0, 180.0)
