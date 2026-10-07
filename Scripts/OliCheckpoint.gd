extends Area3D

@export var checkpoint_index: int = 0
@onready var spawn: Marker3D = $Spawn
@onready var ring: MeshInstance3D = $Ring
var active: bool = false

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group('Player') and body.is_on_floor():
			get_parent().get_parent().activate_checkpoint(self)

func set_active(value: bool) -> void:
	active = value
	var material := ring.material_override as StandardMaterial3D
	material.albedo_color = Color(0.2,1.0,0.65) if active else Color(1.0,0.68,0.2)
	material.emission = material.albedo_color

