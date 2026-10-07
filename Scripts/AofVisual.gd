@tool
extends Node3D
## Articulated low-poly model; geometry is editable in Aof.tscn.
var phase: float = 0.0
@onready var body: Node3D = $Body
@onready var left_arm: Node3D = $Body/LeftArm
@onready var right_arm: Node3D = $Body/RightArm
@onready var left_leg: Node3D = $Body/LeftLeg
@onready var right_leg: Node3D = $Body/RightLeg

func animate(delta: float, speed: float, grounded: bool, vertical_speed: float, running: bool) -> void:
	phase += delta * (11.0 if running else 7.0) * clampf(speed / 3.5, 0.25, 1.5)
	var moving := clampf(speed / 3.5, 0.0, 1.0)
	var stride := sin(phase) * moving * (0.85 if running else 0.5)
	var blend := 1.0 - exp(-16.0 * delta)
	var arm_left := -stride
	var arm_right := stride
	var leg_left := stride
	var leg_right := -stride
	var lean := 0.12 * moving if running else 0.03 * moving
	var bob := absf(cos(phase)) * 0.035 * moving
	if not grounded:
		arm_left = -1.05 if vertical_speed > 0.0 else -0.45
		arm_right = arm_left
		leg_left = 0.45
		leg_right = -0.3
		lean = -0.06
		bob = 0.0
	left_arm.rotation.x = lerpf(left_arm.rotation.x, arm_left, blend)
	right_arm.rotation.x = lerpf(right_arm.rotation.x, arm_right, blend)
	left_leg.rotation.x = lerpf(left_leg.rotation.x, leg_left, blend)
	right_leg.rotation.x = lerpf(right_leg.rotation.x, leg_right, blend)
	body.rotation.x = lerpf(body.rotation.x, lean, blend)
	body.position.y = lerpf(body.position.y, bob, blend)
