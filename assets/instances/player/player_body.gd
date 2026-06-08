class_name PlayerBody extends CharacterBody3D

signal queue_jump()

var input_move_direction: Vector2

var _wants_jump: bool = false


func _process(_delta: float) -> void:
	input_move_direction = Input.get_vector("move_left", "move_right", "move_backward", "move_forward")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_jump") and not _wants_jump:
		queue_jump.emit()
