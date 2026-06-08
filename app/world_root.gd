class_name WorldRoot extends Node3D

var world: World


func _ready() -> void:
	world = World.new()
	add_child(PlayerScene.build(world))
