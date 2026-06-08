class_name PlayerBody extends CharacterBody3D

var world: World
var collider: CollisionShape3D
var camera: PlayerCamera

var current_height: float
var is_crouching: bool


func bind(ctx: World) -> void:
	world = ctx


func _ready() -> void:
	current_height = world.tuning.standing_height


func _physics_process(delta: float) -> void:
	simulate(PlayerInputFrame.capture(), delta)


## Runtime step: resolve velocity from frame + tuning, then move.
func simulate(frame: PlayerInputFrame, delta: float) -> void:
	resolve_velocity(frame, delta)
	move_and_slide()


## Pure step: writes velocity + crouch state from frame + tuning, no physics
## server calls. Headless tests drive this directly and assert on velocity.
func resolve_velocity(frame: PlayerInputFrame, delta: float) -> void:
	var t := world.tuning
	var grounded := is_on_floor()

	var move_world_dir := Vector3(frame.move_dir.x, 0.0, frame.move_dir.y) * basis.inverse()

	var target_speed := t.run_speed if frame.sprint else t.walk_speed
	is_crouching = frame.crouch
	if is_crouching and grounded:
		target_speed = t.crouch_speed

	var height_rate := t.height_lerp_rate * delta
	if is_crouching:
		current_height = lerp(current_height, t.crouch_height, height_rate * t.crouch_down_speed_multiplier)
	else:
		current_height = lerp(current_height, t.standing_height, height_rate)
	collider.shape.height = current_height

	var wish_velocity := Vector2(move_world_dir.x, move_world_dir.z) * target_speed
	var horizontal := Vector2(velocity.x, velocity.z)
	var has_input := move_world_dir.length_squared() > 0.0
	var pull := t.acceleration if has_input else t.friction
	horizontal = horizontal.move_toward(wish_velocity, pull * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y

	if frame.jump and grounded:
		velocity.y = t.jump_force

	if not grounded:
		velocity.y -= t.gravity * delta
