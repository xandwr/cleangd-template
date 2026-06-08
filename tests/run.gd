# godot --headless -s res://tests/run.gd
extends SceneTree


func _initialize() -> void:
	var failures := 0
	for suite in [MotorTests.new(), PipelineTests.new()]:
		failures += suite.run(self)
	print("=== %s ===" % ("ALL PASS" if failures == 0 else "%d FAILURE(S)" % failures))
	quit(failures)
