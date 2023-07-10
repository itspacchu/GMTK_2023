extends Node3D

enum {CUBE_TYPE=0,SPH_TYPE,CYL_TYPE};

@export var rigidBody:RigidBody3D;
@export var ScalingFactor:float = 3.1;
@export var player_color:Color = Color.DARK_SALMON
@export var current_type = -1

@export var player_entity:Node3D;

static var SENS:float = 0.001
@export var JUMP_VELOCITY = 1

var is_on_ground:bool = true
var is_slamming:bool = false
var is_jumping:bool = false
var previous_player_pos = Vector3.ZERO

@onready var collision_box = %PlayerBody/collision
@onready var mesh =%PlayerBody/mesh
@onready var death_particles = preload("res://Models/ded.tscn")

var PLAYER_SLAM_TRIGGER = 15
var ENEMY_SLAM_COOLDOWN = 3

var can_slam_again = true

var kinetic_damage_scalar:float = 1
var impact_damage_scalar:float = 1

var force_scalar:float = 1
var torque_scalar:float = 1

var cur_delta = 0

@export var health = 10

func _ready():
	switch_enemies(CUBE_TYPE)

func process_jumping(_delta):
	if(is_on_ground):
		$GroundTesting/jump_particles.emitting = true
		rigidBody.apply_central_impulse(200 * _delta * JUMP_VELOCITY * rigidBody.mass * (Vector3.UP))

func _process(_delta):
	if(is_on_ground):
		if(is_slamming):
			$GroundTesting/slam_light.visible = false
			$GroundTesting/slam_particles.emitting = false
			rigidBody.linear_velocity = 0.1*rigidBody.linear_velocity
			rigidBody.angular_damp = 0
			
			slam_targets(_delta)
			is_slamming = false
			
	if(player_entity.glob_pos.distance_squared_to($ai_walk/PlayerBody.global_position) < 50):
		player_slammer()


func slam_targets(_delta,tot_time=0):
	if(player_entity.glob_pos.distance_squared_to($ai_walk/PlayerBody.global_position) < PLAYER_SLAM_TRIGGER):
		player_entity.health -= impact_damage_scalar
		player_entity.take_dmg()
		player_entity.get_node("PlayerBody").linear_velocity *= 0.5
		player_entity.get_node("PlayerBody").angular_velocity *= 0.5
		player_entity.get_node("PlayerBody").apply_central_impulse(200 * _delta * tot_time/10 * rigidBody.mass * (Vector3.UP))


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

		kinetic_damage_scalar = 1
		impact_damage_scalar = 15
		%SlamSFX.pitch_scale = 0.5
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
		%SlamSFX.pitch_scale = 3
		kinetic_damage_scalar = 5
		impact_damage_scalar = 5
		
		JUMP_VELOCITY = 0.3
		torque_scalar = 7.0
		force_scalar = 0.5
		
	elif(new_type == CYL_TYPE):
		%SlamSFX.pitch_scale = 1
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
		impact_damage_scalar = 10
		
		JUMP_VELOCITY = 0.3
		torque_scalar = 1.5
		force_scalar = 1.5
		
	current_type = new_type
	return 1

func process_slam(_delta):
	randomize()
	can_slam_again = false
	if(is_slamming):
		return 0
	is_slamming = true
	rigidBody.angular_damp = 10
	rigidBody.linear_velocity = 0.05*rigidBody.linear_velocity
	rigidBody.angular_velocity = 0.1*rigidBody.angular_velocity
	$GroundTesting/slam_particles.emitting = true
	$GroundTesting/slam_light.visible = true
	$ai_walk/PlayerBody.apply_central_impulse(200 * _delta * 100 * 0.5 * rigidBody.mass * (Vector3.DOWN))
	$SlamCoolDown.start(ENEMY_SLAM_COOLDOWN)
	%SlamSFX.play(0.15)
	


func _physics_process(_delta):
	cur_delta = _delta
	#if((previous_player_pos - player_entity.glob_pos).length_squared() > 1):
	$ai_walk/PlayerBody/NavigationAgent3D.target_position = player_entity.glob_pos + Vector3(randi_range(1,1.5),0,randi_range(1,1.5))
	is_on_ground = $GroundTesting.get_collider() != null
	var hbar = "["
	for i in range(10):
		if(i < health):
			hbar += "#"
		else:
			hbar += " "
	hbar += "]"
	$ai_walk/PlayerBody/Label3D.text = hbar
	if(health < 1):
		commit_die()
	
func commit_die():
	var attached_particle = death_particles.instantiate()
	get_parent().add_child(attached_particle)
	attached_particle.global_position = $ai_walk/PlayerBody.global_position
	attached_particle.emitting = true
	visible = false
	global_position = Vector3(1000,1000,1000)
	if(player_entity.selected_body == self):
		player_entity.selected_body = null
	queue_free()



func player_slammer():
	if(can_slam_again):
		if(is_on_ground and not is_slamming):
			process_jumping(cur_delta)
			$JumpSlamTimer.start(0.25)


func _on_jump_slam_timer_timeout():
	if(player_entity.glob_pos.distance_squared_to($ai_walk/PlayerBody.global_position) < PLAYER_SLAM_TRIGGER):
		process_slam(cur_delta)


func _on_slam_cool_down_timeout():
	can_slam_again = true
