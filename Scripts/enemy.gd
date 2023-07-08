extends Node3D

enum {CUBE_TYPE=0,SPH_TYPE,CYL_TYPE};

@export var rigidBody:RigidBody3D;
@export var ScalingFactor:float = 3.1;
@export var JUMP_VELOCITY = 0.3
@export var player_color:Color = Color.DARK_SALMON
@export var current_type = -1

static var SENS:float = 0.001

var is_on_ground:bool = true
var is_slamming:bool = false
var is_jumping:bool = false

@onready var collision_box = %PlayerBody/collision
@onready var mesh =%PlayerBody/mesh


var kinetic_damage_scalar:float = 1
var impact_damage_scalar:float = 1

var force_scalar:float = 1
var torque_scalar:float = 1


@export var health = 10

func switch_enemies(new_type):
	if(new_type == current_type):
		return 0


	elif(new_type == CUBE_TYPE):
		var new_shape = BoxShape3D.new()
		var new_mesh = BoxMesh.new()
		new_shape.size = Vector3.ONE
		new_mesh.size = new_shape.size
		collision_box.shape = new_shape
		mesh.mesh = new_mesh

		kinetic_damage_scalar = 0.5
		impact_damage_scalar = 5
		
		JUMP_VELOCITY = 0.3
		torque_scalar = 1.2
		force_scalar = 5.0

		
	elif(new_type == SPH_TYPE):
		var new_shape = SphereShape3D.new()
		var new_mesh = SphereMesh.new()
		new_shape.radius = 0.5
		new_mesh.radius = new_shape.radius
		collision_box.shape = new_shape
		mesh.mesh = new_mesh
		
		kinetic_damage_scalar = 5
		impact_damage_scalar = 0.2
		
		JUMP_VELOCITY = 0.3
		torque_scalar = 7.0
		force_scalar = 0.5
		
	elif(new_type == CYL_TYPE):
		var new_shape = CylinderShape3D.new()
		var new_mesh = CylinderMesh.new()
		new_shape.radius = 0.25
		new_mesh.top_radius = new_shape.radius
		new_mesh.bottom_radius = new_shape.radius
		new_shape.height = 1.0
		new_mesh.height = new_shape.height
		collision_box.shape = new_shape
		mesh.mesh = new_mesh
		
		kinetic_damage_scalar = 2.5
		impact_damage_scalar = 2.5
		
		JUMP_VELOCITY = 0.3
		torque_scalar = 1.5
		force_scalar = 1.5
		
	current_type = new_type
	return 1


func _enter_tree():
	switch_enemies(current_type)
	
func _ready():
	#switch_enemies(int(Time.get_ticks_msec())%3)
	pass
