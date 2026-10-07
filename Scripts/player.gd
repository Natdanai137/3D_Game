extends CharacterBody3D

@export_category("Aof movement")
@export var move_speed: float = 3.5
@export var run_speed: float = 6.0
@export var jump_force: float = 6.0
@export var acceleration: float = 24.0
@export var air_acceleration: float = 12.0
@export var gravity: float = 19.6
@export var coyote_time: float = 0.10
@export var jump_buffer: float = 0.12
@export_range(1, 5) var jump_limit: int = 3
@onready var model = $CharacterModel
@onready var spring_arm = %Gimbal
@onready var particle_trail: CPUParticles3D = $ParticleTrail
@onready var footsteps: AudioStreamPlayer3D = $Footsteps
var floor_grace: float = 0.0
var buffered_jump: float = 0.0
var jumps_used: int = 0

func _physics_process(delta: float) -> void:
	var controls_active := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if controls_active else Vector2.ZERO
	var direction := Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm.rotation.y)
	var running := controls_active and Input.is_action_pressed("sprint")
	var speed := run_speed if running else move_speed
	var rate := acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, direction.x * speed, rate * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, rate * delta)
	update_jump_state(delta)
	if controls_active and Input.is_action_just_pressed("jump"):
		buffered_jump = jump_buffer
	if not try_buffered_jump() and not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.1:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(velocity.x, velocity.z), 1.0 - exp(-14.0 * delta))
	model.animate(delta, horizontal_speed, is_on_floor(), velocity.y, running)
	particle_trail.emitting = is_on_floor() and horizontal_speed > 4.0
	footsteps.stream_paused = not (is_on_floor() and horizontal_speed > 0.3)
	footsteps.pitch_scale = 1.15 if running else 0.8

func update_jump_state(delta: float) -> void:
	if is_on_floor() and velocity.y <= 0.0:
		jumps_used = 0
		floor_grace = coyote_time
	else:
		floor_grace = maxf(0.0, floor_grace - delta)
		# Walking off an edge uses the ground jump after the grace window.
		if floor_grace == 0.0 and jumps_used == 0:
			jumps_used = 1
	buffered_jump = maxf(0.0, buffered_jump - delta)

func try_buffered_jump() -> bool:
	if buffered_jump <= 0.0 or jumps_used >= jump_limit:
		return false
	jumps_used += 1
	velocity.y = jump_force
	floor_grace = 0.0
	buffered_jump = 0.0
	AudioManager.jump_sfx.pitch_scale = 1.0 + (jumps_used - 1) * 0.08
	AudioManager.jump_sfx.play()
	return true

func reset_to_spawn(spawn: Vector3) -> void:
	global_position = spawn
	velocity = Vector3.ZERO
	floor_grace = 0.0
	buffered_jump = 0.0
	jumps_used = 0
	spring_arm.snap_to_player()
