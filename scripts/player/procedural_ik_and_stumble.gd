# ==============================================================================
# PROCEDURAL ANIMATION, FOOT/HAND IK & STUMBLE RECOVERY FOR GODOT 4.x
# Reverse-Engineered from Playdead's HuddleFootProbe, BoyReachPlateauState & FallUtils
# ==============================================================================
class_name InsideProceduralIKAndStumble
extends Node

signal stumbled(landing_velocity: float)
signal hard_fall_detected(fatal: bool)
signal hand_contact_entered(surface_normal: Vector3, contact_point: Vector3)
signal hand_contact_exited()

@export_group("Target Nodes")
@export var character_body_path: NodePath
@export var skeleton_path: NodePath
@export var left_foot_bone_name: String = "Foot_L"
@export var right_foot_bone_name: String = "Foot_R"
@export var left_hand_bone_name: String = "Hand_L"
@export var right_hand_bone_name: String = "Hand_R"

@export_group("Foot IK Terrain Adaptation")
@export var foot_raycast_length: float = 0.95
@export var foot_offset_y: float = 0.08
@export var ik_blend_speed: float = 16.0
@export var foot_spacing_x: float = 0.22

@export_group("Hand-Snapping Wall/Obstacle Touch")
@export var hand_raycast_distance: float = 0.85
@export var shoulder_height_y: float = 0.9
@export var hand_reach_smoothing: float = 12.0

@export_group("Fall Damage & Stumble Thresholds")
@export var stumble_velocity_threshold: float = -10.5 # Landing speed triggering stumble (m/s)
@export var fatal_fall_velocity_threshold: float = -17.5 # Speed triggering instant death (m/s)
@export var stumble_recovery_time: float = 0.48       # Movement lock duration during stumble (sec)

# Runtime state
var character: CharacterBody3D = null
var skeleton: Skeleton3D = null
var is_stumbling: bool = false
var stumble_timer: float = 0.0
var previous_velocity_y: float = 0.0

var left_foot_ik_target: Vector3 = Vector3.ZERO
var right_foot_ik_target: Vector3 = Vector3.ZERO
var hand_ik_target: Vector3 = Vector3.ZERO
var hand_is_touching: bool = false

func _ready() -> void:
	character = get_node_or_null(character_body_path) as CharacterBody3D
	skeleton = get_node_or_null(skeleton_path) as Skeleton3D

func _physics_process(delta: float) -> void:
	if not character:
		return
		
	_evaluate_landing_stumble(delta)
	_solve_foot_ik(delta)
	_solve_hand_wall_touch(delta)
	
	previous_velocity_y = character.velocity.y

# --- STUMBLE & HARD LANDING KINEMATICS ---
func _evaluate_landing_stumble(delta: float) -> void:
	if is_stumbling:
		stumble_timer -= delta
		# Restrict horizontal control during stumble roll
		character.velocity.x = move_toward(character.velocity.x, 0.0, 18.0 * delta)
		if stumble_timer <= 0.0:
			is_stumbling = false
		return
		
	# Detect floor collision transition
	if character.is_on_floor() and previous_velocity_y < stumble_velocity_threshold:
		if previous_velocity_y <= fatal_fall_velocity_threshold:
			emit_signal("hard_fall_detected", true)
			if character.has_method("die_by_fall"):
				character.call("die_by_fall")
		else:
			is_stumbling = true
			stumble_timer = stumble_recovery_time
			emit_signal("stumbled", previous_velocity_y)
			emit_signal("hard_fall_detected", false)

# --- FOOT IK (SLOPE & STAIRS SOLVER) ---
func _solve_foot_ik(delta: float) -> void:
	if not character.is_on_floor():
		return
		
	var space_state = character.get_world_3d().direct_space_state
	var char_pos = character.global_position
	
	# Left Foot Raycast
	var l_origin = char_pos + Vector3(-foot_spacing_x, 0.5, 0)
	var l_target = l_origin + Vector3(0, -foot_raycast_length, 0)
	var l_query = PhysicsRayQueryParameters3D.create(l_origin, l_target)
	l_query.exclude = [character.get_rid()]
	var l_result = space_state.intersect_ray(l_query)
	
	# Right Foot Raycast
	var r_origin = char_pos + Vector3(foot_spacing_x, 0.5, 0)
	var r_target = r_origin + Vector3(0, -foot_raycast_length, 0)
	var r_query = PhysicsRayQueryParameters3D.create(r_origin, r_target)
	r_query.exclude = [character.get_rid()]
	var r_result = space_state.intersect_ray(r_query)
	
	if not l_result.is_empty():
		var target_y = l_result.position.y + foot_offset_y
		left_foot_ik_target.y = lerp(left_foot_ik_target.y, target_y, ik_blend_speed * delta)
		
	if not r_result.is_empty():
		var target_y = r_result.position.y + foot_offset_y
		right_foot_ik_target.y = lerp(right_foot_ik_target.y, target_y, ik_blend_speed * delta)

# --- HAND-SNAPPING TO WALLS & EDGES ---
func _solve_hand_wall_touch(delta: float) -> void:
	var facing = 1.0
	if "facing_direction" in character:
		facing = character.get("facing_direction")
	elif character.velocity.x != 0.0:
		facing = sign(character.velocity.x)
		
	var space_state = character.get_world_3d().direct_space_state
	var origin = character.global_position + Vector3(0, shoulder_height_y, 0)
	var target = origin + Vector3(facing * hand_raycast_distance, 0, 0)
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [character.get_rid()]
	var result = space_state.intersect_ray(query)
	
	if not result.is_empty():
		var hit_pos = result.position
		var hit_normal = result.normal
		hand_ik_target = hand_ik_target.lerp(hit_pos, hand_reach_smoothing * delta)
		if not hand_is_touching:
			hand_is_touching = true
			emit_signal("hand_contact_entered", hit_normal, hit_pos)
	else:
		if hand_is_touching:
			hand_is_touching = false
			emit_signal("hand_contact_exited")
