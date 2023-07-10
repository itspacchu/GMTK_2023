extends RigidBody3D

@export var parent:Node3D;
@export var SPEED = 10;
var safe_velocity_set = Vector3.ZERO

func _physics_process(delta):
	if $NavigationAgent3D.is_target_reachable():
		var tgt = $NavigationAgent3D.get_next_path_position()
		var velocity = global_transform.origin.direction_to(tgt).normalized() * SPEED
		apply_central_impulse(0.01*Vector3(velocity.x,0,velocity.z))
		if(angular_velocity.length_squared() < 10):
			apply_torque_impulse(0.02*Vector3(velocity.z,0,-velocity.x))

		
func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	if(not parent.is_slamming and parent.is_on_ground):
		safe_velocity_set = safe_velocity
		linear_velocity.x = safe_velocity.x
		linear_velocity.z = safe_velocity.z
		apply_torque_impulse(-0.01*Vector3(safe_velocity.x,0,safe_velocity.z))
