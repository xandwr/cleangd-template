class_name PlayerBodyController extends CharacterBody3D

@export var walk_speed: float = 3.5
@export var run_speed: float = 6.5
@export var crouch_speed: float = 1.5
@export var jump_force: float = 5.0
@export var standing_height: float = 1.8
@export var crouch_height: float = 1.0
@export var crouch_down_speed_multiplier: float = 2.0 ## how much faster crouch is than stand

@onready var collider: CollisionShape3D = %PlayerCollider
@onready var camera_controller: PlayerCameraController = %PlayerCameraController

var current_speed: float
var current_height: float
var move_input_dir: Vector2
var move_world_dir: Vector3
var is_crouching: bool = false


func _ready() -> void:
	camera_controller.body = self


func _process(delta: float) -> void:
	move_input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	move_world_dir = Vector3(move_input_dir.x, 0.0, move_input_dir.y) * basis.inverse()
	current_speed = lerp(current_speed, run_speed, 8 * delta) if Input.is_action_pressed("move_sprint") else lerp(current_speed, walk_speed, 8 * delta)
	is_crouching = true if Input.is_action_pressed("move_crouch") else false
	current_speed = lerp(current_speed, crouch_speed, 8 * delta) if is_crouching and is_on_floor() else current_speed
	current_height = lerp(current_height, crouch_height, 8 * delta * crouch_down_speed_multiplier) if is_crouching else lerp(current_height, standing_height, 8 * delta)
	collider.shape.height = current_height


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_jump") and is_on_floor(): velocity.y = jump_force


func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y += get_gravity().y * delta
	
	velocity.x = move_world_dir.x * current_speed
	velocity.z = move_world_dir.z * current_speed
	
	move_and_slide()
