## Camera arm for the Player. Accumulates mouse look intent (fed by PlayerInput via
## the Player root) into yaw and clamped pitch. Knows nothing about input actions.
class_name PlayerCamera extends SpringArm3D

const THIRD_PERSON_CAM_DISTANCE: float = 2.5

enum CameraMode {
	FIRST_PERSON,
	THIRD_PERSON
}

@export var sensitivity := 0.003
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var pitch_limit := deg_to_rad(85.0)
@export var camera_mode: CameraMode = CameraMode.FIRST_PERSON

var _yaw := 0.0
var _pitch := 0.0


func _process(_delta: float) -> void:
	spring_length = THIRD_PERSON_CAM_DISTANCE if camera_mode == CameraMode.THIRD_PERSON else 0.0


func add_look_delta(delta: Vector2) -> void:
	# Ignore look while the cursor is free (paused, a menu open, window unfocused)
	# so a confined-but-visible cursor can't drag the view around.
	if not MouseLock.is_captured():
		return
	_yaw -= delta.x * sensitivity
	_pitch = clampf(_pitch - delta.y * sensitivity, -pitch_limit, pitch_limit)
	rotation = Vector3(_pitch, _yaw, 0.0)
