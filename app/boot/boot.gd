extends Node


func _ready() -> void:
	if OS.is_debug_build():
		print("CleanGD Template loaded.")
