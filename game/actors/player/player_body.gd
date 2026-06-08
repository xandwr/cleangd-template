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

## Crouch geometry. The standing capsule is stand_height tall with its feet at the
## body origin (y=0); crouch_height is the shrunk size. eye_height is where the
## camera sits standing, crouch_eye_height where it sits fully crouched. Source-like
## crouch-jumping comes from *where* the collider anchors per state (see _apply_crouch).
@export var stand_height := 1.8
@export var crouch_height := 1.0
@export var eye_height := 1.6
@export var crouch_eye_height := 0.9
## How fast the crouch transition eases, in 0..1 units per second (9 ≈ 0.11s full).
@export var crouch_speed_rate := 9.0

enum MoveState { GROUND, AIR }

var _move_direction := Vector2.ZERO
var _sprinting := false
var _crouching := false
var _jump_queued := false
var _state := MoveState.GROUND

## 0 = fully standing, 1 = fully crouched. Lerped toward the held intent each tick;
## the collider height, anchor, and eye height all read off this single value.
var _crouch_t := 0.0
## The state the collider anchor was last positioned for. Tracked so a ground<->air
## transition re-anchors even when _crouch_t isn't moving (e.g. jumping while fully
## crouched needs the feet to tuck up).
var _anchor_state := MoveState.GROUND

@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var _collider: CollisionShape3D = $Collider
@onready var _camera: Node3D = %PlayerCamera

## Live capsule we resize for crouch, and its radius captured once. Duplicated so
## resizing mutates this instance, not the shared scene sub-resource (which would
## leak crouch state across reloads / other players). Radius is read into a plain
## float because the headroom probe must not depend on reading it back off the
## live shape mid-physics, where Jolt can hand back a zero before the rebuild.
var _capsule: CapsuleShape3D
var _radius := 0.2


func _ready() -> void:
	var source := _collider.shape as CapsuleShape3D
	_radius = source.radius
	_capsule = source.duplicate()
	_collider.shape = _capsule
	_apply_crouch()


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

	_update_crouch(delta)

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


## Ease _crouch_t toward the held intent, then push it into the collider/camera.
## Standing back up is gated on headroom: if something is directly above, we stay
## crouched (cap _crouch_t) until it clears, so we never grow into geometry.
func _update_crouch(delta: float) -> void:
	var target := 1.0 if _crouching else 0.0
	if target < _crouch_t and not _has_headroom():
		target = _crouch_t

	# Re-apply on any height change, and on a ground<->air flip so the anchor swaps
	# even while fully crouched (height steady) — that flip is the crouch-jump tuck.
	var height_changing := not is_equal_approx(_crouch_t, target)
	if height_changing:
		_crouch_t = move_toward(_crouch_t, target, crouch_speed_rate * delta)
	if height_changing or _state != _anchor_state:
		_apply_crouch()


## Map _crouch_t to the live capsule height, its anchor, and the eye height.
##
## The anchor is the whole crouch-jump trick. On the ground the feet stay planted
## (collider bottom at y=0), so crouching lowers the head. In the air we anchor the
## *head* instead: the feet tuck up toward it, lifting the collider's bottom off the
## ground. That raised floor is what lets a crouch in mid-jump clear a ledge you'd
## otherwise clip. The eye follows the head either way so the view never pops.
func _apply_crouch() -> void:
	var height := lerpf(stand_height, crouch_height, _crouch_t)
	_capsule.height = height

	var feet_anchored := _state == MoveState.GROUND
	var center := height * 0.5 if feet_anchored else stand_height - height * 0.5
	_collider.position.y = center
	_anchor_state = _state

	_camera.position.y = lerpf(eye_height, crouch_eye_height, _crouch_t)


## Is the space above clear enough to stand back up? Tests a full-height standing
## capsule, centered where it would sit with feet planted, against the body's own
## collision mask. Empty result means nothing's in the way. Excludes self so we
## don't collide with our own crouched shape.
func _has_headroom() -> bool:
	var probe := CapsuleShape3D.new()
	probe.radius = _radius
	probe.height = stand_height

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.transform = global_transform.translated(Vector3(0.0, stand_height * 0.5, 0.0))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]

	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


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
