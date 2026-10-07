extends Area3D

# ---------- VARIABLES ---------- #

# Looked up by group instead of unique-name ($%) since this script lives inside a
# reusable obstacle scene instanced into different levels, each with its own spawn marker.
@onready var player = get_tree().get_first_node_in_group("Player")

# ---------- SIGNALS ---------- #

func _on_body_entered(body):
	# Sends the player back to the level's spawn point, just like the DeadZone
	if body.is_in_group("Player"):
		var spawn_position = get_tree().get_first_node_in_group("SpawnPosition")
		AudioManager.jump_sfx.play()
		AudioManager.jump_sfx.pitch_scale = 0.6
		if spawn_position:
			player.reset_to_spawn(spawn_position.global_position)
		player.velocity = Vector3.ZERO
