class_name PlayerCameraController extends SpringArm3D

enum CameraMode { FIRST_PERSON, THIRD_PERSON }

@export var camera_mode: CameraMode = CameraMode.FIRST_PERSON
@export var third_person_cam_distance: float = 3.0
@export var mouse_sensitivity: float = 0.002

@onready var camera: Camera3D = %PlayerCamera

var body: CharacterBody3D
var mouse_locked: bool = true
var pitch: float = 0.0
var yaw: float = 0.0


func _ready() -> void:
	_update_mouselock()
	_update_camera_mode()


func _update_mouselock() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_locked else Input.MOUSE_MODE_VISIBLE


func _update_camera_mode() -> void:
	match camera_mode:
		CameraMode.FIRST_PERSON: spring_length = 0.0
		CameraMode.THIRD_PERSON: spring_length = third_person_cam_distance


func _process(_delta: float) -> void:
	if mouse_locked:
		rotation.x = clamp(rotation.x + (pitch * mouse_sensitivity), -PI/2, PI/2)
		if body: body.rotation.y += yaw * mouse_sensitivity
	
	pitch = 0.0
	yaw = 0.0


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pitch -= event.relative.y
		yaw -= event.relative.x
	
	if event.is_action_pressed("pause"):
		mouse_locked = not mouse_locked
		_update_mouselock()
