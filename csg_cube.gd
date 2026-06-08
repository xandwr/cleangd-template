class_name CSGCube extends CSGBox3D

enum PhysicsMode { STATIC, DYNAMIC }

@export var physics_mode: PhysicsMode = PhysicsMode.STATIC:
	set(value):
		if value == physics_mode:
			return
		physics_mode = value
		if is_node_ready():
			_apply_physics_mode()

var _phys_object: RigidBody3D


func _ready() -> void:
	_apply_physics_mode()

	await get_tree().create_timer(5).timeout
	physics_mode = PhysicsMode.DYNAMIC


func _apply_physics_mode() -> void:
	if physics_mode == PhysicsMode.DYNAMIC:
		if not is_instance_valid(_phys_object):
			_spawn_physics_body()
	else:
		if is_instance_valid(_phys_object):
			_phys_object.queue_free()
			_phys_object = null
		visible = true


func _spawn_physics_body() -> void:
	_phys_object = RigidBody3D.new()

	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = material
	_phys_object.add_child(mesh)

	var col := CollisionShape3D.new()
	var shp := BoxShape3D.new()
	shp.size = size
	col.shape = shp
	_phys_object.add_child(col)

	var spawn_transform := global_transform
	get_parent().add_child.call_deferred(_phys_object)
	_phys_object.set_deferred(&"global_transform", spawn_transform)

	await get_tree().process_frame
	visible = false
