class_name PlayerBody extends CharacterBody3D

@export var jump_force: float = 4.5

signal queue_jump()

var input_move_direction: Vector2

var _wants_jump: bool = false


func _process(_delta: float) -> void:
	input_move_direction = Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	
	if Input.is_action_pressed("move_jump") and not _wants_jump:
		queue_jump.emit()
		_wants_jump = true


func _input(event: InputEvent) -> void:
	if event.is_action_released("move_jump") and _wants_jump: _wants_jump = false


func _physics_process(delta: float) -> void:
	if _wants_jump and is_on_floor():
		velocity.y = jump_force
		_wants_jump = false
	
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	move_and_slide()
