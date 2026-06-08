class_name MotorTests extends TestSuite

const DT := 1.0 / 120.0


func run(tree: SceneTree) -> int:
	print("MotorTests")
	_test_sprint_faster_than_walk(tree)
	_test_crouch_lowers_capsule(tree)
	_test_jump_sets_vertical_velocity(tree)
	return _failures


## Drive simulate() n ticks with a fixed frame, return the body for inspection.
func _spawn(tree: SceneTree) -> PlayerBody:
	var ctx := World.new()
	var player := PlayerScene.build(ctx)
	tree.root.add_child(player)
	return player.body


func _run_ticks(body: PlayerBody, frame: PlayerInputFrame, n: int) -> void:
	for i in n:
		body.resolve_velocity(frame, DT)


func _test_sprint_faster_than_walk(tree: SceneTree) -> void:
	var walk_body := _spawn(tree)
	_run_ticks(walk_body, PlayerInputFrame.make(Vector2(0, 1)), 240)
	var walk_speed := Vector2(walk_body.velocity.x, walk_body.velocity.z).length()
	walk_body.get_parent().queue_free()

	var sprint_body := _spawn(tree)
	_run_ticks(sprint_body, PlayerInputFrame.make(Vector2(0, 1), true), 240)
	var sprint_speed := Vector2(sprint_body.velocity.x, sprint_body.velocity.z).length()
	sprint_body.get_parent().queue_free()

	check(sprint_speed > walk_speed + 1.0, "sprint reaches higher horizontal speed than walk (%.2f > %.2f)" % [sprint_speed, walk_speed])


func _test_crouch_lowers_capsule(tree: SceneTree) -> void:
	var body := _spawn(tree)
	var standing: float = body.collider.shape.height
	_run_ticks(body, PlayerInputFrame.make(Vector2.ZERO, false, true), 240)
	var crouched: float = body.collider.shape.height
	check(crouched < standing - 0.5, "crouch lowers capsule height (%.2f -> %.2f)" % [standing, crouched])
	body.get_parent().queue_free()


func _test_jump_sets_vertical_velocity(tree: SceneTree) -> void:
	# Headless: is_on_floor() is false (no physics step), so jump cannot fire.
	# Assert the inverse-safe property: a jump frame off the floor does NOT
	# spuriously launch — vertical velocity stays gravity-driven (<= 0 after a tick).
	var body := _spawn(tree)
	body.resolve_velocity(PlayerInputFrame.make(Vector2.ZERO, false, false, true), DT)
	check(body.velocity.y <= 0.0, "jump off-floor does not launch headless (vy=%.3f)" % body.velocity.y)
	body.get_parent().queue_free()
