# ==============================================================================
# THE HUDDLE (FLESH BLOB) SOFT-BODY CONTROLLER FOR GODOT 4.x
# Reverse-Engineered from Playdead's Huddle, AudioHuddleRoll & FakeSpring
# ==============================================================================
class_name InsideHuddleSoftBodyController
extends RigidBody3D

signal wall_smashed(wall_node: Node3D, impact_energy: float)
signal limb_planted(limb_position: Vector3)
signal huddle_rolled(speed: float)

@export_group("Mass & Roll Dynamics")
@export var huddle_mass: float = 480.0             # Massive inertia (kg)
@export var roll_torque_force: float = 6200.0      # Rotational torque applied during movement
@export var max_roll_angular_velocity: float = 8.5 # Maximum rolling speed (rad/s)
@export var com_shift_offset: float = 0.45         # Center of mass offset toward roll direction
@export var ground_traction_force: float = 2400.0  # Linear forward push when rolling

@export_group("Destruction & Impact")
@export var break_energy_threshold: float = 2600.0 # Kinetic energy required to breach walls (Joules)
@export var camera_shake_energy_multiplier: float = 0.0004

@export_group("Soft-Body Spring Node Network")
@export var spring_node_count: int = 12            # Radial deformation anchor count
@export var rest_radius: float = 1.35              # Uncompressed resting radius (m)
@export var spring_stiffness: float = 240.0        # Restoring spring constant
@export var spring_damping: float = 14.0           # Shock absorption damping

@export_group("Procedural Limbs / Grasping Hands")
@export var limb_count: int = 8
@export var limb_reach_distance: float = 1.65
@export var limb_pull_strength: float = 380.0

# Runtime arrays
var spring_positions: Array[Vector3] = []
var spring_velocities: Array[Vector3] = []
var limb_contact_points: Array[Vector3] = []

func _ready() -> void:
	mass = huddle_mass
	# Lock Z movement & rotations except X (rolling axis in 2.5D)
	axis_lock_linear_z = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	
	# Initialize radial spring positions around core
	for i in range(spring_node_count):
		var angle = (float(i) / float(spring_node_count)) * TAU
		var local_pos = Vector3(cos(angle) * rest_radius, sin(angle) * rest_radius, 0.0)
		spring_positions.append(local_pos)
		spring_velocities.append(Vector3.ZERO)

func _physics_process(delta: float) -> void:
	_handle_huddle_input(delta)
	_solve_softbody_springs(delta)
	_evaluate_procedural_limbs(delta)
	
	# Keep strictly in 2.5D plane
	global_position.z = 0.0
	linear_velocity.z = 0.0

func _handle_huddle_input(delta: float) -> void:
	var move_x: float = Input.get_axis("ui_left", "ui_right")
	
	if move_x != 0.0:
		# 1. Dynamic Center of Mass Shift: leaning forward creates continuous forward roll
		center_of_mass = Vector3(move_x * com_shift_offset, -0.15, 0.0)
		
		# 2. Rotational Torque around Z axis (Z is perpendicular to 2D view screen)
		# Note: In Godot right-handed system, rolling right means rotating clockwise around Z axis
		var torque = Vector3(0, 0, -move_x * roll_torque_force)
		apply_torque(torque * delta)
		
		# 3. Ground contact traction force
		var is_contacting_ground = false
		for pt in limb_contact_points:
			if pt != Vector3.ZERO:
				is_contacting_ground = true
				break
				
		if is_contacting_ground or linear_velocity.y <= 0.5:
			apply_central_force(Vector3(move_x * ground_traction_force, 0, 0) * delta)
			
		emit_signal("huddle_rolled", abs(linear_velocity.x))
	else:
		center_of_mass = Vector3(0.0, -0.1, 0.0)

# --- SOFT-BODY SPRING NETWORK DEFORMATION ---
func _solve_softbody_springs(delta: float) -> void:
	var current_rot = global_transform.basis
	
	for i in range(spring_node_count):
		var angle = (float(i) / float(spring_node_count)) * TAU
		var target_local = Vector3(cos(angle) * rest_radius, sin(angle) * rest_radius, 0.0)
		
		# Centrifugal & compression displacement
		var displacement = spring_positions[i] - target_local
		var spring_force = -spring_stiffness * displacement
		var damping_force = -spring_damping * spring_velocities[i]
		
		var total_accel = spring_force + damping_force
		spring_velocities[i] += total_accel * delta
		spring_positions[i] += spring_velocities[i] * delta

# --- PROCEDURAL LIMB REACHING & FLOOR GRASP ---
func _evaluate_procedural_limbs(delta: float) -> void:
	var space_state = get_world_3d().direct_space_state
	limb_contact_points.clear()
	
	for i in range(limb_count):
		# Calculate world angle of rotating limb socket
		var socket_angle = (float(i) / float(limb_count)) * TAU + rotation.z
		var socket_dir = Vector3(cos(socket_angle), sin(socket_angle), 0.0)
		
		# Only limbs pointing towards the bottom hemisphere check for floor grasp
		if socket_dir.y < 0.1:
			var ray_start = global_position + socket_dir * (rest_radius * 0.8)
			var ray_end = ray_start + socket_dir * limb_reach_distance
			
			var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
			query.exclude = [self.get_rid()]
			var result = space_state.intersect_ray(query)
			
			if not result.is_empty():
				limb_contact_points.append(result.position)
				# Pull blob forward slightly when hand plants
				var pull_dir = -socket_dir
				apply_force(pull_dir * limb_pull_strength * delta, result.position - global_position)
				emit_signal("limb_planted", result.position)
			else:
				limb_contact_points.append(Vector3.ZERO)
		else:
			limb_contact_points.append(Vector3.ZERO)

# --- IMPACT BREACHING (WALL SMASHING) ---
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if collider and collider.is_in_group("destructible_wall"):
			var impact_vel = state.get_contact_impulse(i).length()
			var kinetic_energy = 0.5 * huddle_mass * (impact_vel * impact_vel)
			
			if kinetic_energy >= break_energy_threshold:
				emit_signal("wall_smashed", collider, kinetic_energy)
				if collider.has_method("shatter_breach"):
					collider.call("shatter_breach", impact_vel, state.get_contact_local_normal(i))
