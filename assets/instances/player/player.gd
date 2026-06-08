class_name Player extends Node

# Root node references
@onready var mesh: MeshInstance3D = %Mesh
@onready var collider: CollisionShape3D = %Collider
@onready var camera_arm: SpringArm3D = %CameraArm
@onready var camera: Camera3D = %Camera3D

# Components
@onready var player_body: PlayerBody = %PlayerBody
