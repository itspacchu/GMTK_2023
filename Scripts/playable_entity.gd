extends Node3D
enum {CUBE_TYPE=0,SPH_TYPE,CYL_TYPE,DEFAULT_CUBE};

@export var rigidBody:RigidBody3D;
@export var ScalingFactor:float = 3.1;
@export var JUMP_VELOCITY = 0.3
@export var player_color:Color = Color.DARK_SALMON
static var SENS:float = 0.001

var slam_time = 0

var is_on_ground:bool = true
var is_slamming:bool = false
var is_jumping:bool = false
var current_type = SPH_TYPE

@onready var collision_box = $PlayerBody/collision
@onready var mesh = $PlayerBody/mesh


var kinetic_damage_scalar:float = 1
var impact_damage_scalar:float = 1

var force_scalar:float = 1
var torque_scalar:float = 1

var selected_body = null


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

		$GroundTesting.target_position = Vector3(0,-1,0)
		
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

		$GroundTesting.target_position = Vector3(0,-0.6,0)
		
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

		$GroundTesting.target_position = Vector3(0,-0.6,0)
		
	current_type = new_type
	return 1


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	switch_enemies(CUBE_TYPE)

func _process(_delta):
	is_on_ground = $GroundTesting.get_collider() != null
	if(Input.is_action_pressed("ui_accept")):
		process_jumping(_delta)
	var input_dir = Input.get_vector("ui_up", "ui_down", "ui_right", "ui_left")
	var force_dir = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	var torque_dir = ($playerPivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var direction = ($playerPivot.transform.basis * Vector3(force_dir.x, 0, force_dir.y)).normalized()

	rigidBody.apply_torque_impulse(torque_scalar*torque_dir*_delta)
	rigidBody.apply_central_impulse(force_scalar*direction*_delta)

	if(is_on_ground):
		if(is_slamming):
			$GroundTesting/slam_light.visible = false
			$GroundTesting/slam_particles.emitting = false
			rigidBody.linear_velocity = 0.1*rigidBody.linear_velocity
			rigidBody.angular_damp = 0
			
			slam_targets(_delta,Time.get_ticks_msec() - slam_time)
			print(Time.get_ticks_msec() - slam_time)
			slam_time = 0
			is_slamming = false
		$playerPivot/ForwardArrow.position.y =  lerp($playerPivot/ForwardArrow.position.y,$GroundTesting.get_collider().position.y,_delta)
	else:
		if(Input.is_action_just_pressed("slam")):
			process_slam(_delta)
	
	if(is_slamming):
		rigidBody.linear_damp = lerp(rigidBody.linear_damp,1.0,0.04*_delta)
	else:
		rigidBody.linear_damp = lerp(rigidBody.linear_damp,0.0,10.0* _delta)

	if(selected_body):
		%hand_selector.visible = true
		%hand_selector.global_position = selected_body.get_node("ai_walk/PlayerBody").global_position
	else:
		%hand_selector.visible = false

func process_slam(_delta):
	if(is_slamming):
		return 0
	slam_time = Time.get_ticks_msec()
	is_slamming = true
	rigidBody.angular_damp = 10
	rigidBody.linear_velocity = 0.1*rigidBody.linear_velocity
	$GroundTesting/slam_particles.emitting = true
	$GroundTesting/slam_light.visible = true
	rigidBody.apply_central_impulse(200 * _delta * 100 * 0.5 * rigidBody.mass * (Vector3.DOWN))

func slam_targets(_delta,tot_time=0):
	for enemy in $GroundTesting/Area3D.get_overlapping_bodies():
		if(enemy.is_in_group("Enemies")):
			enemy.parent.health -= impact_damage_scalar
			enemy.linear_velocity *= 0.1
			enemy.angular_velocity *= 0.1
			enemy.apply_central_impulse(200 * _delta * tot_time/10 * rigidBody.mass * (Vector3.UP))

	
func process_jumping(_delta):
	is_jumping = true
	if(is_on_ground):
		$GroundTesting/jump_particles.emitting = true
		rigidBody.apply_central_impulse(200 * _delta * JUMP_VELOCITY * rigidBody.mass * (Vector3.UP))

func _input(event):
	if event is InputEventMouseButton:
		if(event.button_index == MOUSE_BUTTON_MASK_LEFT and event.pressed and selected_body):
			var old_thing = current_type
			switch_enemies(selected_body.current_type)
			selected_body.switch_enemies(old_thing)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		$playerPivot.rotate_y(-event.relative.x * SENS)
		$playerPivot/camPivot.rotate_x(-event.relative.y * SENS)
		$playerPivot/camPivot.rotation.x = clamp($playerPivot/camPivot.rotation.x, deg_to_rad(-50), deg_to_rad(-10))

func _on_area_3d_body_entered(body):
	if(body.is_in_group("Enemies")):
		if(body.get_parent().get_parent().current_type == current_type):
			return
		selected_body = body.get_parent().get_parent()
