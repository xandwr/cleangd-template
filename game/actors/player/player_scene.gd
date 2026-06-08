class_name PlayerScene

const _MESH := preload("res://assets/instances/player/player_mesh.tscn") ## art only, opaque


static func build(ctx: World) -> Player:
	var t := ctx.tuning

	var player := Player.new()
	player.name = "Player"

	var body := PlayerBody.new()
	body.name = "PlayerBody"

	var collider := _collision_capsule(t)
	body.collider = collider
	body.add_child(collider)

	body.add_child(_MESH.instantiate())

	var cam := _camera(t)
	cam.body = body
	body.camera = cam
	body.add_child(cam)

	player.body = body
	player.add_child(body)
	player.add_child(_hud())

	player.bind(ctx)
	return player


static func _collision_capsule(t: MovementTuning) -> CollisionShape3D:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = t.standing_height

	var collider := CollisionShape3D.new()
	collider.name = "PlayerCollider"
	collider.shape = shape
	collider.position.y = t.standing_height * 0.5 # feet at y=0
	return collider


static func _camera(t: MovementTuning) -> PlayerCamera:
	var cam := PlayerCamera.new()
	cam.name = "PlayerCamera"
	cam.position.y = 1.6 # eye height

	var camera := Camera3D.new()
	camera.name = "PlayerCamera3D"
	cam.camera = camera
	cam.add_child(camera)
	return cam


static func _hud() -> CanvasLayer:
	var hud := CanvasLayer.new()
	hud.name = "Hud"

	var crosshair := Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "+"
	crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud.add_child(crosshair)
	return hud
