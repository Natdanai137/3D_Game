extends Node3D
## Plays the skeletal animation clips imported with Aof_Rigged.glb.
@onready var animation: AnimationPlayer = $Rig/AnimationPlayer

func _ready() -> void:
	for clip in ['Idle','Walk','Run']:
		animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation.play('Idle')

func animate(_delta: float, speed: float, grounded: bool, vertical_speed: float, running: bool) -> void:
	var clip := 'Idle'
	if not grounded:
		clip = 'Jump' if vertical_speed > 0.0 else 'Fall'
	elif speed > 0.15:
		clip = 'Run' if running else 'Walk'
	if animation.current_animation != clip:
		animation.play(clip,0.12)
	animation.speed_scale = clampf(speed / (3.5 if running else 1.8),0.25,2.2) if clip in ['Walk','Run'] else 1.0
