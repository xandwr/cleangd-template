class_name PlayerInputFrame extends RefCounted

var move_dir: Vector2 ## raw WASD vector, x=left/right, y=forward/back
var sprint: bool
var crouch: bool
var jump: bool ## edge-triggered: pressed this frame

## The single place that reads Input at runtime. Tests use make() instead.
static func capture() -> PlayerInputFrame:
	var frame := PlayerInputFrame.new()
	frame.move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	frame.sprint = Input.is_action_pressed("move_sprint")
	frame.crouch = Input.is_action_pressed("move_crouch")
	frame.jump = Input.is_action_just_pressed("move_jump")
	return frame


## Hand-constructable frame for headless tests, no Input device required.
static func make(new_move_dir: Vector2, new_sprint: bool = false, new_crouch: bool = false, new_jump: bool = false) -> PlayerInputFrame:
	var frame := PlayerInputFrame.new()
	frame.move_dir = new_move_dir
	frame.sprint = new_sprint
	frame.crouch = new_crouch
	frame.jump = new_jump
	return frame
