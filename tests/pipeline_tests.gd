class_name PipelineTests extends TestSuite

const DT := 1.0 / 120.0


func run(tree: SceneTree) -> int:
	print("PipelineTests")
	_test_builder_constructs_player(tree)
	_test_input_frame_moves_body(tree)
	_test_two_worlds_coexist(tree)
	return _failures


func _test_builder_constructs_player(tree: SceneTree) -> void:
	var ctx := World.new()
	var player := PlayerScene.build(ctx)
	tree.root.add_child(player)
	check(player.body != null, "builder wires player.body")
	check(player.world == ctx, "bind injects the World ctx")
	check(player.body.collider != null and player.body.camera != null, "body has collider + camera")
	player.queue_free()


func _test_input_frame_moves_body(tree: SceneTree) -> void:
	var ctx := World.new()
	var player := PlayerScene.build(ctx)
	tree.root.add_child(player)
	var frame := PlayerInputFrame.make(Vector2(0, 1))
	player.body.resolve_velocity(frame, DT)
	check(player.body.velocity.length() > 0.0, "forward input produces velocity")
	player.queue_free()


func _test_two_worlds_coexist(tree: SceneTree) -> void:
	# The whole point of killing globals: two worlds, side by side, no shared state.
	var a := World.new()
	var b := World.new()
	a.tuning.walk_speed = 2.0
	b.tuning.walk_speed = 10.0

	var pa := PlayerScene.build(a)
	var pb := PlayerScene.build(b)
	tree.root.add_child(pa)
	tree.root.add_child(pb)

	var frame := PlayerInputFrame.make(Vector2(0, 1))
	for i in 240:
		pa.body.resolve_velocity(frame, DT)
		pb.body.resolve_velocity(frame, DT)

	var sa := Vector2(pa.body.velocity.x, pa.body.velocity.z).length()
	var sb := Vector2(pb.body.velocity.x, pb.body.velocity.z).length()
	check(sb > sa + 2.0, "two worlds tune independently (slow=%.2f, fast=%.2f)" % [sa, sb])

	pa.queue_free()
	pb.queue_free()
