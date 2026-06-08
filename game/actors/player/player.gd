## Root of the Player actor. Owns nothing but the wiring: it connects PlayerInput's
## intent signals to handlers on the body and camera, which stay ignorant of input.
## This is the one place to read to see how a key turns into motion.
class_name Player extends Node

@onready var player_body: PlayerBody = %PlayerBody
@onready var player_camera: PlayerCamera = %PlayerCamera
@onready var player_input: PlayerInput = %PlayerInput


func _ready() -> void:
	player_input.move_direction_changed.connect(player_body.set_move_direction)
	player_input.jump_pressed.connect(player_body.jump)
	player_input.sprint_changed.connect(player_body.set_sprinting)
	player_input.crouch_changed.connect(player_body.set_crouching)

	player_input.mouse_delta_changed.connect(player_camera.add_look_delta)
	player_input.pause_pressed.connect(_on_pause_pressed)

	# Look splits: the camera pitches itself and hands yaw to the body, which turns
	# to face it (carrying the camera) and resolves movement relative to that facing.
	player_camera.yaw_changed.connect(player_body.set_yaw)

	# Gameplay owns the cursor while the player is active; the seam re-captures
	# whenever nothing (pause, a dialog) is holding it free.
	MouseLock.capture()


## Toggle a single held release: first press frees the cursor, next re-captures.
## Held as a handle rather than a flag so an overlapping unlocker (e.g. a dialog)
## still keeps the cursor free until it too releases.
var _pause_unlock: MouseLockHandle


func _on_pause_pressed() -> void:
	if _pause_unlock:
		_pause_unlock.release()
		_pause_unlock = null
	else:
		_pause_unlock = MouseLock.request_unlock("pause")
