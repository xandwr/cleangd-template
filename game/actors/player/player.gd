class_name Player extends Node

var world: World
var body: PlayerBody


func bind(ctx: World) -> void:
	world = ctx
	body.bind(ctx)
