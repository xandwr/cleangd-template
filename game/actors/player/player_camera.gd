## Camera arm for the Player, parented under PlayerBody. Splits mouse look intent:
## pitch is applied locally here (tilting the view up/down), yaw is emitted for the
## body to apply to its own Y rotation so the physics body turns with the look and
## the camera follows as its child. Knows nothing about input actions.
class_name PlayerCamera extends SpringArm3D

const THIRD_PERSON_CAM_DISTANCE: float = 2.5

enum CameraMode {
	FIRST_PERSON,
	THIRD_PERSON
}

## Yaw the body should turn to (radians). The camera never yaws itself; it turns
## with the body it hangs under.
signal yaw_changed(yaw: float)

@export var sensitivity := 0.003
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var pitch_limit := deg_to_rad(85.0)
@export var camera_mode: CameraMode = CameraMode.FIRST_PERSON

var _yaw := 0.0
var _pitch := 0.0


func _ready() -> void:
	# SpringArm3D sweeps a shape (or a ray) each frame to find where the camera
	# should rest. With no shape set, Jolt's cast_motion rejects the null query and
	# spams errors. A small sphere gives the sweep something valid to cast.
	if not shape:
		var probe := SphereShape3D.new()
		probe.radius = 0.2
		shape = probe


func _process(_delta: float) -> void:
	spring_length = THIRD_PERSON_CAM_DISTANCE if camera_mode == CameraMode.THIRD_PERSON else 0.0


func add_look_delta(delta: Vector2) -> void:
	# Ignore look while the cursor is free (paused, a menu open, window unfocused)
	# so a confined-but-visible cursor can't drag the view around.
	if not MouseLock.is_captured():
		return
	_pitch = clampf(_pitch - delta.y * sensitivity, -pitch_limit, pitch_limit)
	rotation.x = _pitch

	_yaw -= delta.x * sensitivity
	yaw_changed.emit(_yaw)
