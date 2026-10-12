# ==============================================================================
# WATER CREATURE KINEMATICS & LIGHT REPELLENT FSM FOR GODOT 4.x
# Reverse-Engineered from Playdead's WaterGirl, VisualWaterGirl & UnderwaterCoil
# ==============================================================================
class_name InsideWaterCreature3D
extends Node3D

signal creature_repelled_by_light(spotlight: SpotLight3D)
signal ambush_charge_started()
signal player_caught(player_node: Node3D)

enum CreatureState {
	DORMANT,        # Lurking in deep water out of camera bounds
	STALKING,       # Gliding gracefully around perimeter of visibility
	LIGHT_BLINDED,  # Recoiling, writhing in pain when struck by direct cone of light
	PREPARE_AMBUSH, # Lurking behind underwater structures or waiting for light turn
	AMBUSH_CHARGE,  # High-speed strike targeting the player
	LATCH_KILL      # Dragging player down into the pitch-black abyss
}

@export_group("Target References")
@export var player_target_path: NodePath
@export var submarine_spotlight_path: NodePath

@export_group("Swimming Kinematics")
@export var stalk_speed: float = 3.4               # Normal graceful cruising speed (m/s)
@export var ambush_speed: float = 7.8              # Explosive attack velocity (m/s)
@export var repel_speed: float = 4.2               # Backpedal retreat velocity (m/s)
@export var turn_speed: float = 5.0                # Angular responsiveness
@export var undulation_frequency: float = 4.5      # Spine oscillation frequency (Hz)
@export var undulation_amplitude: float = 0.35     # Sine wave sway lateral offset (m)
@export var segment_count: int = 8                 # Number of trailing hair/spine nodes
@export var segment_spacing: float = 0.32          # Distance between chain links

@export_group("Light Sensitivity & Repellent")
@export var light_exposure_threshold: float = 0.25 # Seconds under light to trigger full recoil
@export var light_repel_distance_margin: float = 2.0 # Minimum standoff distance from light beam
@export var ambush_delay_after_dark: float = 0.35  # Window of darkness before launching strike

# Runtime variables
var current_state: CreatureState = CreatureState.STALKING
var player_target: Node3D = null
var spotlight: SpotLight3D = null

var velocity: Vector3 = Vector3.ZERO
var exposure_timer: float = 0.0
var darkness_timer: float = 0.0
var swim_time: float = 0.0
var spine_segments: Array[Vector3] = []

func _ready() -> void:
	player_target = get_node_or_null(player_target_path) as Node3D
	spotlight = get_node_or_null(submarine_spotlight_path) as SpotLight3D
	
	# Initialize spine chain
	for i in range(segment_count):
		spine_segments.append(global_position - Vector3(0, 0, i * segment_spacing))

func _physics_process(delta: float) -> void:
	swim_time += delta
	if not player_target:
		return
		
	var is_in_light = _check_spotlight_exposure()
	
	match current_state:
		CreatureState.STALKING:
			_process_stalking(delta, is_in_light)
		CreatureState.LIGHT_BLINDED:
			_process_light_blinded(delta, is_in_light)
		CreatureState.PREPARE_AMBUSH:
			_process_prepare_ambush(delta, is_in_light)
		CreatureState.AMBUSH_CHARGE:
			_process_ambush_charge(delta, is_in_light)
		CreatureState.LATCH_KILL:
			_process_latch_kill(delta)
			
	# Update trailing spline/spine kinematics (Verlet-like chain)
	_update_spine_chain(delta)
	
	# Clamp to 2.5D plane
	global_position.z = 0.0

# --- SPOTLIGHT CONE EVALUATION ---
func _check_spotlight_exposure() -> bool:
	if not spotlight or not spotlight.visible:
		return false
		
	var light_pos = spotlight.global_position
	var to_creature = global_position - light_pos
	to_creature.z = 0.0
	var dist = to_creature.length()
	
	if dist > spotlight.spot_range or dist < 0.2:
		return false
		
	var light_dir = -spotlight.global_transform.basis.z.normalized()
	light_dir.z = 0.0
	light_dir = light_dir.normalized()
	
	var angle = rad_to_deg(light_dir.angle_to(to_creature.normalized()))
	if angle > (spotlight.spot_angle * 0.5):
		return false
		
	# Raycast occlusion check (is there a rock/pillar blocking the beam?)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(light_pos, global_position)
	var result = space_state.intersect_ray(query)
	
	if result.is_empty() or result.collider == self:
		return true
		
	return false

# --- STATE PROCESSORS ---
func _process_stalking(delta: float, in_light: bool) -> void:
	if in_light:
		exposure_timer += delta
		if exposure_timer >= light_exposure_threshold:
			_change_state(CreatureState.LIGHT_BLINDED)
			return
	else:
		exposure_timer = max(0.0, exposure_timer - delta * 2.0)
		
	# Circle around player at safe stalking radius (approx 6-8 meters)
	var to_player = player_target.global_position - global_position
	to_player.z = 0.0
	var dist = to_player.length()
	
	var desired_pos: Vector3
	if dist > 8.0:
		desired_pos = player_target.global_position - to_player.normalized() * 6.5
	else:
		# Flank laterally
		var tangent = Vector3(-to_player.y, to_player.x, 0).normalized()
		desired_pos = player_target.global_position + tangent * 6.0
		
	var move_dir = (desired_pos - global_position).normalized()
	velocity = velocity.lerp(move_dir * stalk_speed, turn_speed * delta)
	global_position += velocity * delta

func _process_light_blinded(delta: float, in_light: bool) -> void:
	if not in_light:
		_change_state(CreatureState.PREPARE_AMBUSH)
		darkness_timer = 0.0
		return
		
	# Recoil away from the light source with violent writhing
	var light_pos = spotlight.global_position if spotlight else player_target.global_position
	var recoil_dir = (global_position - light_pos).normalized()
	recoil_dir.z = 0.0
	
	# Add chaotic lateral tremor
	var tremor = sin(swim_time * 18.0) * 1.5
	recoil_dir.y += tremor
	
	velocity = velocity.lerp(recoil_dir.normalized() * repel_speed, 8.0 * delta)
	global_position += velocity * delta
	emit_signal("creature_repelled_by_light", spotlight)

func _process_prepare_ambush(delta: float, in_light: bool) -> void:
	if in_light:
		_change_state(CreatureState.LIGHT_BLINDED)
		return
		
	darkness_timer += delta
	# After short pause in shadows, strike!
	if darkness_timer >= ambush_delay_after_dark:
		_change_state(CreatureState.AMBUSH_CHARGE)
		emit_signal("ambush_charge_started")

func _process_ambush_charge(delta: float, in_light: bool) -> void:
	if in_light:
		_change_state(CreatureState.LIGHT_BLINDED)
		return
		
	var to_player = (player_target.global_position - global_position)
	to_player.z = 0.0
	var dist = to_player.length()
	
	if dist <= 0.8:
		_change_state(CreatureState.LATCH_KILL)
		emit_signal("player_caught", player_target)
		return
		
	velocity = velocity.lerp(to_player.normalized() * ambush_speed, 12.0 * delta)
	global_position += velocity * delta

func _process_latch_kill(delta: float) -> void:
	# Drag player rapidly into bottom abyss
	global_position += Vector3(0, -5.5, 0) * delta
	if player_target:
		player_target.global_position = global_position
		if player_target.has_method("die_by_drowning_mermaid"):
			player_target.call("die_by_drowning_mermaid")

# --- PROCEDURAL SPINE UNDULATION (VERLET CHAIN) ---
func _update_spine_chain(delta: float) -> void:
	if spine_segments.is_empty():
		return
		
	# First segment follows head with undulation
	var lateral_wave = sin(swim_time * undulation_frequency) * undulation_amplitude
	var head_pos = global_position + Vector3(0, lateral_wave, 0)
	spine_segments[0] = head_pos
	
	# Enforce distance constraint down the chain
	for i in range(1, spine_segments.size()):
		var prev = spine_segments[i - 1]
		var curr = spine_segments[i]
		var dir = (curr - prev).normalized()
		spine_segments[i] = prev + dir * segment_spacing

func _change_state(new_state: CreatureState) -> void:
	current_state = new_state
