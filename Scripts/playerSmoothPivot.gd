extends Node3D

@export var playerBody:RigidBody3D;
@export var LERP_SPEED:float = 10.0;

func _physics_process(delta):
	self.global_position = lerp(self.global_position,playerBody.global_position,LERP_SPEED*delta)
