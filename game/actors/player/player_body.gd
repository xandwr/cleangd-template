## Physical body of the Player. Receives movement intent as setters (driven by
## PlayerInput via the Player root) and resolves it into camera-relative motion
## every physics tick. Knows nothing about input actions or events.
class_name PlayerBody extends CharacterBody3D

@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var crouch_speed := 2.5
@export var jump_velocity := 5.5
@export var acceleration := 12.0

## Set by Player so movement can be resolved relative to where we're looking.
var camera: Node3D

var _move_direction := Vector2.ZERO
var _sprinting := false
var _crouching := false
var _jump_queued := false

@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func set_move_direction(direction: Vector2) -> void:
	_move_direction = direction


func set_sprinting(active: bool) -> void:
	_sprinting = active


func set_crouching(active: bool) -> void:
	_crouching = active


## Queued rather than applied immediately so the jump lands on the next physics
## tick, where is_on_floor() is authoritative.
func jump() -> void:
	_jump_queued = true


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if _jump_queued:
		_jump_queued = false
		if is_on_floor():
			velocity.y = jump_velocity

	var target := _planar_velocity()
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)

	move_and_slide()


## Converts the 2D move intent into a world-space planar velocity, relative to the
## camera's yaw when one is bound and falling back to world axes otherwise.
func _planar_velocity() -> Vector3:
	if _move_direction == Vector2.ZERO:
		return Vector3.ZERO

	var look_basis := camera.global_transform.basis if camera else global_transform.basis
	var forward := -look_basis.z
	var right := look_basis.x
	var direction := (right * _move_direction.x + forward * _move_direction.y)
	direction.y = 0.0
	direction = direction.normalized()

	return direction * _current_speed()


func _current_speed() -> float:
	if _crouching:
		return crouch_speed
	if _sprinting:
		return sprint_speed
	return walk_speed
