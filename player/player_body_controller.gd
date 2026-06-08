class_name PlayerBodyController extends CharacterBody3D

@export var walk_speed: float = 3.5
@export var run_speed: float = 6.5
@export var jump_force: float = 4.5

@onready var collider: CollisionShape3D = %PlayerCollider
@onready var camera_controller: PlayerCameraController = %PlayerCameraController

var current_speed: float
var move_input_dir: Vector2
var move_world_dir: Vector3


func _ready() -> void:
	camera_controller.body = self


func _process(_delta: float) -> void:
	move_input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	move_world_dir = Vector3(move_input_dir.x, 0.0, move_input_dir.y) * basis.inverse()
	current_speed = run_speed if Input.is_action_pressed("move_sprint") else walk_speed


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_jump") and is_on_floor(): velocity.y = jump_force


func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y += get_gravity().y * delta
	
	velocity.x = move_world_dir.x * current_speed
	velocity.z = move_world_dir.z * current_speed
	
	move_and_slide()
