class_name MovementTuning extends RefCounted

var walk_speed: float = 3.5
var run_speed: float = 6.5
var crouch_speed: float = 1.5
var jump_force: float = 5.0
var gravity: float = 25.0 ## matches project.godot 3d/default_gravity

var standing_height: float = 1.8
var crouch_height: float = 1.0
var crouch_down_speed_multiplier: float = 2.0 ## how much faster crouch is than stand

var acceleration: float = 40.0 ## how hard velocity drives toward the wish vector
var friction: float = 30.0 ## how hard velocity decays toward zero with no input
var height_lerp_rate: float = 8.0 ## how fast capsule height eases toward its target
