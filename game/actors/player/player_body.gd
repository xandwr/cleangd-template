## Physical body of the Player. Receives movement and look-yaw intent as setters
## (driven by PlayerInput and PlayerCamera via the Player root) and resolves them
## into motion every physics tick. The body owns yaw, so its child camera turns
## with it; movement is relative to the body's own facing. Knows nothing about
## input actions or events.
##
## Movement is Quake/Source-inspired: a small state machine (GROUND vs AIR) picks
## the per-tick rules. On the ground we apply friction then accelerate toward the
## wish direction; in the air we skip friction and clamp acceleration to a tiny
## projection of speed onto the wish dir. That clamp is the whole trick: it caps
## how much you can gain along where you already look, but not sideways, so
## turning while you strafe lets you build speed (air-strafing, bunnyhopping).
class_name PlayerBody extends CharacterBody3D

## Top planar speed the ground accelerate step targets, per mode.
@export var walk_speed := 3.5
@export var sprint_speed := 6.5
@export var crouch_speed := 1.5
@export var jump_velocity := 4.5

## Ground feel. Friction bleeds speed each tick; ground_accel is how hard we pull
## toward the wish dir (higher = snappier, more Quake-like; lower = more drift).
@export var friction := 6.0
@export var ground_accel := 80.0
## stop_speed floors the friction calculation so you don't asymptotically creep:
## below it, friction is computed as if you were at least this fast, killing the
## last sliver of velocity cleanly.
@export var stop_speed := 2.0

## Air feel. air_accel is intentionally low: it's how fast you can *redirect*
## momentum mid-jump, not a speed source. air_speed_cap bounds how much you can
## gain along where you already point each tick, keeping strafing controllable
## rather than instant.
@export var air_accel := 20.0
@export var air_speed_cap := 1.2

enum MoveState { GROUND, AIR }

var _move_direction := Vector2.ZERO
var _sprinting := false
var _crouching := false
var _jump_queued := false
var _state := MoveState.GROUND

@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func set_move_direction(direction: Vector2) -> void:
	_move_direction = direction


## Turn to face the look yaw (radians). The camera, parented here, follows.
func set_yaw(yaw: float) -> void:
	rotation.y = yaw


func set_sprinting(active: bool) -> void:
	_sprinting = active


func set_crouching(active: bool) -> void:
	_crouching = active


## Queued rather than applied immediately so the jump lands on the next physics
## tick, where is_on_floor() is authoritative.
func jump() -> void:
	_jump_queued = true


func _physics_process(delta: float) -> void:
	_state = MoveState.GROUND if is_on_floor() else MoveState.AIR

	var wish_dir := _wish_direction()

	match _state:
		MoveState.GROUND:
			_ground_move(wish_dir, delta)
		MoveState.AIR:
			_air_move(wish_dir, delta)
			velocity.y -= _gravity * delta

	move_and_slide()


## On the ground: bleed speed to friction, then accelerate toward the wish dir up
## to the mode's target speed. A queued jump fires here (after friction, before the
## move) so the launch keeps the speed we just shaped, then flips us to the air.
func _ground_move(wish_dir: Vector3, delta: float) -> void:
	_apply_friction(delta)

	if _jump_queued:
		_jump_queued = false
		velocity.y = jump_velocity
		_state = MoveState.AIR
		# Air rules for the launch tick so a strafe-jump can start redirecting at once.
		_accelerate(wish_dir, _current_speed() * air_speed_cap, air_accel, delta)
		return

	velocity.y = 0.0
	_accelerate(wish_dir, _current_speed(), ground_accel, delta)


## In the air: no friction, and the accelerate target is clamped tiny (air_speed_cap)
## so you barely gain along where you already point, but redirecting the wish dir
## while you turn still adds speed sideways. That asymmetry is air-strafing.
func _air_move(wish_dir: Vector3, delta: float) -> void:
	_accelerate(wish_dir, _current_speed() * air_speed_cap, air_accel, delta)


## Quake friction: scale planar velocity down by a drop proportional to current
## speed (or stop_speed, whichever is larger) so slow movement still stops cleanly.
func _apply_friction(delta: float) -> void:
	var planar := Vector3(velocity.x, 0.0, velocity.z)
	var speed := planar.length()
	if speed < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var control := maxf(speed, stop_speed)
	var drop := control * friction * delta
	var new_speed := maxf(speed - drop, 0.0) / speed
	velocity.x *= new_speed
	velocity.z *= new_speed


## Quake accelerate: only add speed up to the gap between our current speed *along
## wish_dir* and target_speed, scaled by accel. Because the cap is on the projection
## onto wish_dir, velocity perpendicular to it is untouched, which is what lets a
## turning strafe redirect momentum without paying friction for it.
func _accelerate(wish_dir: Vector3, target_speed: float, accel: float, delta: float) -> void:
	if wish_dir == Vector3.ZERO:
		return

	var planar := Vector3(velocity.x, 0.0, velocity.z)
	var current_speed := planar.dot(wish_dir)
	var add_speed := target_speed - current_speed
	if add_speed <= 0.0:
		return

	# Step toward the target by accel*delta; the gap (add_speed) already shrinks as
	# we approach, so this eases out on its own. Don't scale the step by target_speed
	# or the ramp goes exponential and higher modes launch disproportionately hard.
	var accel_speed := minf(accel * delta, add_speed)
	velocity.x += wish_dir.x * accel_speed
	velocity.z += wish_dir.z * accel_speed


## The desired move direction in world space, relative to the body's own facing
## (which look-yaw keeps pointed where the camera looks). Normalized so diagonal
## input isn't faster; zero when there's no input.
func _wish_direction() -> Vector3:
	if _move_direction == Vector2.ZERO:
		return Vector3.ZERO

	var facing := global_transform.basis
	var forward := -facing.z
	var right := facing.x
	var direction := right * _move_direction.x + forward * _move_direction.y
	direction.y = 0.0
	return direction.normalized()


func _current_speed() -> float:
	if _crouching:
		return crouch_speed
	if _sprinting:
		return sprint_speed
	return walk_speed
