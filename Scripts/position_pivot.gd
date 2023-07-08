extends Node3D

@export var playerBody:RigidBody3D;

func _process(_delta):
	self.global_position = playerBody.global_position


