class_name PlayerBody extends CharacterBody3D

var world: World
var collider: CollisionShape3D
var camera: PlayerCamera

var current_speed: float
var current_height: float
var is_crouching: bool


func bind(ctx: World) -> void:
	world = ctx


func _ready() -> void:
	current_speed = world.tuning.walk_speed
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
	var rate := t.speed_lerp_rate * delta
	var grounded := is_on_floor()

	var move_world_dir := Vector3(frame.move_dir.x, 0.0, frame.move_dir.y) * basis.inverse()

	var target_speed := t.run_speed if frame.sprint else t.walk_speed
	current_speed = lerp(current_speed, target_speed, rate)

	is_crouching = frame.crouch
	if is_crouching and grounded:
		current_speed = lerp(current_speed, t.crouch_speed, rate)

	if is_crouching:
		current_height = lerp(current_height, t.crouch_height, rate * t.crouch_down_speed_multiplier)
	else:
		current_height = lerp(current_height, t.standing_height, rate)
	collider.shape.height = current_height

	if frame.jump and grounded:
		velocity.y = t.jump_force

	if not grounded:
		velocity.y -= t.gravity * delta

	velocity.x = move_world_dir.x * current_speed
	velocity.z = move_world_dir.z * current_speed
