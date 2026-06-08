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
static func make(move_dir: Vector2, sprint: bool = false, crouch: bool = false, jump: bool = false) -> PlayerInputFrame:
	var frame := PlayerInputFrame.new()
	frame.move_dir = move_dir
	frame.sprint = sprint
	frame.crouch = crouch
	frame.jump = jump
	return frame
