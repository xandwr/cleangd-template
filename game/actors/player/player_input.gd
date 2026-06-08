## Translates raw input into intent signals for the rest of the Player to consume.
## Owns no state beyond what's needed to debounce the analog signals; emits
## nothing on frames where nothing changed.
class_name PlayerInput extends Node

## Movement intent on the XZ plane, normalized-ish from Input.get_vector.
signal move_direction_changed(direction: Vector2)
## Relative mouse motion this frame (look intent); only while the mouse is captured.
signal mouse_delta_changed(delta: Vector2)

## Discrete action intents: emit on the press edge unless noted.
signal jump_pressed()
signal sprint_changed(active: bool)
signal crouch_changed(active: bool)
signal interact_pressed()
signal primary_pressed()
signal secondary_pressed()
signal pause_pressed()

var _move_direction := Vector2.ZERO
var _sprinting := false
var _crouching := false


func _physics_process(_delta: float) -> void:
	# Poll movement on the physics tick since PlayerBody is a CharacterBody3D.
	var direction := Input.get_vector(
		"move_left", "move_right", "move_backward", "move_forward")
	if direction != _move_direction:
		_move_direction = direction
		move_direction_changed.emit(direction)

	# Held-state actions: emit only on transition.
	var sprinting := Input.is_action_pressed("move_sprint")
	if sprinting != _sprinting:
		_sprinting = sprinting
		sprint_changed.emit(sprinting)

	var crouching := Input.is_action_pressed("move_crouch")
	if crouching != _crouching:
		_crouching = crouching
		crouch_changed.emit(crouching)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta_changed.emit((event as InputEventMouseMotion).relative)
		return

	if event.is_action_pressed("move_jump"):
		jump_pressed.emit()
	elif event.is_action_pressed("fire_interact"):
		interact_pressed.emit()
	elif event.is_action_pressed("fire_primary"):
		primary_pressed.emit()
	elif event.is_action_pressed("fire_secondary"):
		secondary_pressed.emit()


func _input(event: InputEvent) -> void:
	# Pause stays in _input so it fires even when a UI layer is consuming events.
	if event.is_action_pressed("pause"):
		pause_pressed.emit()
