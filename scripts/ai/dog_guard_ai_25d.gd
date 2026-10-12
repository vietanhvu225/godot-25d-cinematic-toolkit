# ==============================================================================
# INSIDE-STYLE 2.5D DOG & GUARD AI STEERING CONTROLLER FOR GODOT 4.x
# Reverse-Engineered from Playdead's ChaserBase, DogChaseDistCompare & HulvBark
# ==============================================================================
class_name InsideDogGuardAI3D
extends CharacterBody3D

signal player_detected(player_position: Vector3)
signal player_lost()
signal state_changed(old_state: int, new_state: int)

enum AIState {
	PATROL,        # Walking waypoints, sniffing ground, idle scans
	SUSPICIOUS,    # Investigating footstep sound / momentary flashlight glimpse
	PURSUIT,       # Full sprint chasing player with pincer/flank steering
	POUNCE_PREP,   # Crouching / growling 0.2s before explosive leap
	POUNCE_LEAP,   # High-speed airborne lunge to pin player
	KILL_SUCCESS   # Instakill cinematic latch on player throat/torso
}

@export_group("AI Sensory & Perception")
@export var vision_range: float = 14.0             # Normal daylight / lit range (m)
@export var vision_range_dark: float = 4.0        # Range in unlit shadows (m)
@export var vision_angle_deg: float = 65.0         # Half-angle of vision cone (deg)
@export var raycast_samples: int = 7               # Multi-raycast density across cone
@export var hearing_range_walk: float = 3.5        # Footstep detection radius (m)
@export var hearing_range_run: float = 9.0         # Sprint footstep detection radius (m)
@export var hearing_range_splash: float = 13.0     # Water splash hearing radius (m)
@export var has_flashlight: bool = false           # Guard carries flashlight
@export var flashlight_node_path: NodePath

@export_group("Locomotion & Steering Tuning")
@export var patrol_speed: float = 1.8              # Trot / walk speed (m/s)
@export var pursuit_speed: float = 6.2             # High-speed hound sprint (m/s)
@export var pounce_speed: float = 9.0              # Explosive lunge velocity (m/s)
@export var pounce_range: float = 3.2              # Distance threshold to launch pounce (m)
@export var acceleration: float = 24.0             # Responsiveness to direction changes
@export var friction: float = 28.0                 # Ground stopping grip
@export var gravity: float = 9.81

@export_group("Flocking & Pincer Coordination")
@export var is_flanker: bool = false               # If true, attempts to cut off player
@export var flank_offset_distance: float = 4.5     # Anticipate ahead of player vector
@export var companion_ai_path: NodePath            # Linked dog/guard for cooperative hunt

@export_group("Patrol Waypoints")
@export var patrol_points: Array[Vector3] = []
@export var waypoint_tolerance: float = 0.5
@export var patrol_idle_wait_time: float = 2.5

# --- RUNTIME VARIABLES ---
var current_state: AIState = AIState.PATROL
var target_player: Node3D = null
var current_waypoint_idx: int = 0
var wait_timer: float = 0.0
var suspicion_position: Vector3 = Vector3.ZERO
var suspicion_alert_level: float = 0.0 # 0.0 to 1.0 (reaches 1.0 -> Pursuit)
var facing_dir: float = 1.0
var pounce_timer: float = 0.0

@onready var flashlight: SpotLight3D = get_node_or_null(flashlight_node_path) as SpotLight3D

func _ready() -> void:
	# Enforce 2.5D planar physics constraint
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	
	# Find player if not assigned
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func _physics_process(delta: float) -> void:
	_update_sensory_perception(delta)
	
	match current_state:
		AIState.PATROL:
			_process_patrol(delta)
		AIState.SUSPICIOUS:
			_process_suspicious(delta)
		AIState.PURSUIT:
			_process_pursuit(delta)
		AIState.POUNCE_PREP:
			_process_pounce_prep(delta)
		AIState.POUNCE_LEAP:
			_process_pounce_leap(delta)
		AIState.KILL_SUCCESS:
			velocity = Vector3.ZERO
			
	# Apply gravity & 2.5D plane lock
	if not is_on_floor():
		velocity.y -= gravity * delta
	global_position.z = 0.0
	velocity.z = 0.0
	
	move_and_slide()

# --- SENSORY EVALUATION (VISION CONE & HEARING) ---
func _update_sensory_perception(delta: float) -> void:
	if not target_player or current_state == AIState.KILL_SUCCESS:
		return
		
	var can_see = _evaluate_vision_cone(target_player.global_position)
	var can_hear = _evaluate_hearing(target_player)
	
	if can_see:
		suspicion_position = target_player.global_position
		suspicion_alert_level = 1.0
		if current_state != AIState.PURSUIT and current_state != AIState.POUNCE_PREP and current_state != AIState.POUNCE_LEAP:
			_change_state(AIState.PURSUIT)
			emit_signal("player_detected", suspicion_position)
	elif can_hear:
		suspicion_position = target_player.global_position
		if current_state == AIState.PATROL:
			_change_state(AIState.SUSPICIOUS)
			suspicion_alert_level = 0.6
	else:
		# Gradually cool down suspicion if target is completely hidden
		if current_state == AIState.SUSPICIOUS:
			suspicion_alert_level = max(0.0, suspicion_alert_level - delta * 0.25)
			if suspicion_alert_level <= 0.0:
				_change_state(AIState.PATROL)
				emit_signal("player_lost")

func _evaluate_vision_cone(target_pos: Vector3) -> bool:
	var to_target = target_pos - global_position
	to_target.z = 0.0
	var dist = to_target.length()
	
	var active_range = vision_range if has_flashlight else vision_range_dark
	if dist > active_range or dist < 0.1:
		return false
		
	var forward = Vector3(facing_dir, 0, 0)
	var angle = rad_to_deg(forward.angle_to(to_target.normalized()))
	if angle > vision_angle_deg:
		return false
		
	# Raycast occlusion check against level geometry
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.4, 0), target_pos + Vector3(0, 0.4, 0))
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return true
	if result.collider == target_player or (result.collider and result.collider.is_in_group("player")):
		return true
		
	return false

func _evaluate_hearing(player_node: Node3D) -> bool:
	var dist = global_position.distance_to(player_node.global_position)
	var p_vel = Vector3.ZERO
	if player_node is CharacterBody3D:
		p_vel = player_node.velocity
	
	var speed = Vector2(p_vel.x, p_vel.y).length()
	var in_water = player_node.get("is_in_water") if "is_in_water" in player_node else false
	
	if in_water and speed > 0.5 and dist <= hearing_range_splash:
		return true
	if speed > 3.0 and dist <= hearing_range_run:
		return true
	if speed > 1.0 and dist <= hearing_range_walk:
		return true
		
	return false

# --- STATE PROCESSORS ---
func _process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		return
		
	var target_pt = patrol_points[current_waypoint_idx]
	var diff_x = target_pt.x - global_position.x
	
	if abs(diff_x) <= waypoint_tolerance:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		wait_timer += delta
		if wait_timer >= patrol_idle_wait_time:
			wait_timer = 0.0
			current_waypoint_idx = (current_waypoint_idx + 1) % patrol_points.size()
	else:
		facing_dir = sign(diff_x)
		velocity.x = move_toward(velocity.x, facing_dir * patrol_speed, acceleration * delta)

func _process_suspicious(delta: float) -> void:
	var diff_x = suspicion_position.x - global_position.x
	facing_dir = sign(diff_x) if abs(diff_x) > 0.2 else facing_dir
	
	if abs(diff_x) > 0.5:
		velocity.x = move_toward(velocity.x, facing_dir * patrol_speed * 1.2, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _process_pursuit(delta: float) -> void:
	var steer_target_x = target_player.global_position.x
	
	# Pincer / Flanking AI steering logic:
	if is_flanker:
		var p_vel_x = 0.0
		if target_player is CharacterBody3D:
			p_vel_x = target_player.velocity.x
		# Flanker cuts off escape route by aiming ahead of player velocity
		steer_target_x += sign(p_vel_x) * flank_offset_distance
		
	var diff_x = steer_target_x - global_position.x
	facing_dir = sign(diff_x) if abs(diff_x) > 0.1 else facing_dir
	velocity.x = move_toward(velocity.x, facing_dir * pursuit_speed, acceleration * delta)
	
	# Check distance to target for pounce leap
	var dist_to_player = global_position.distance_to(target_player.global_position)
	if dist_to_player <= pounce_range and is_on_floor():
		_change_state(AIState.POUNCE_PREP)

func _process_pounce_prep(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * 1.5 * delta)
	pounce_timer += delta
	# Crouch and build tension for 0.22 seconds
	if pounce_timer >= 0.22:
		pounce_timer = 0.0
		_change_state(AIState.POUNCE_LEAP)
		var pounce_dir = (target_player.global_position - global_position).normalized()
		velocity.x = pounce_dir.x * pounce_speed
		velocity.y = 4.2 # Upward leap arc

func _process_pounce_leap(delta: float) -> void:
	var dist = global_position.distance_to(target_player.global_position)
	if dist <= 0.85:
		_change_state(AIState.KILL_SUCCESS)
		if target_player.has_method("die_by_hound"):
			target_player.call("die_by_hound", self)
	elif is_on_floor() and velocity.y <= 0.0:
		# Missed pounce, resume pursuit
		_change_state(AIState.PURSUIT)

func _change_state(new_state: AIState) -> void:
	var old_state = current_state
	current_state = new_state
	emit_signal("state_changed", old_state, new_state)
