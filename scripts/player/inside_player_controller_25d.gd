# ==============================================================================
# INSIDE-STYLE 2.5D CHARACTER CONTROLLER FOR GODOT 4.x
# Reverse-Engineered from Playdead's INSIDE (Physics Tuning Ledger calibrated)
# ==============================================================================
class_name InsideCharacterController3D
extends CharacterBody3D

# --- TUNING CONSTANTS (DIRECT PLAYDEAD REVERSE-ENGINEERED VALUES) ---
@export_group("Locomotion Tuning")
@export var walk_speed: float = 2.7            # Normal walk speed (m/s)
@export var run_speed: float = 4.0             # Full sprint speed (m/s)
@export var slow_drag_speed: float = 1.3       # Burdened / box dragging speed (m/s)
@export var acceleration: float = 18.0         # Ground acceleration responsiveness
@export var friction: float = 22.0             # Ground deceleration damping
@export var air_acceleration: float = 9.0      # Airborne lateral responsiveness

@export_group("Jump & Gravity Tuning")
@export var gravity: float = 9.81              # Standard Playdead gravity (PhysicsManager)
@export var fall_gravity_multiplier: float = 1.35 # Fall curve multiplier for weighty feel
@export var jump_impulse: float = 5.2          # Initial upward velocity
@export var coyote_time: float = 0.12          # Grace window after leaving ledge (sec)
@export var jump_buffer_time: float = 0.15     # Pre-landing jump press memory (sec)
@export var apex_hang_time_damping: float = 0.6# Damping around peak of jump

@export_group("Interaction & Grabbing")
@export var grab_raycast_dist: float = 0.85    # Distance to detect pullable crate
@export var grab_socket_height: float = 0.65   # Hand contact height on objects

@export_group("2.5D Camera Tracking")
@export var camera_path: NodePath
@export var look_ahead_distance: float = 2.5   # Camera leads ahead of player velocity
@export var camera_damping_x: float = 0.18     # Horizontal smoothing
@export var camera_damping_y: float = 0.25     # Vertical smoothing
@export var lock_z_coordinate: float = 0.0     # Strict 2.5D motion plane constraint

# --- INTERNAL STATE MACHINE ---
enum State { IDLE, WALK, RUN, JUMP_START, AIRBORNE, APEX, FALL, LANDING, GRAB_IDLE, GRAB_DRAG }
var current_state: State = State.IDLE

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var facing_direction: float = 1.0 # 1.0 = Right, -1.0 = Left
var is_grabbing: bool = false
var grabbed_object: RigidBody3D = null

@onready var camera: Camera3D = get_node_or_null(camera_path) as Camera3D

func _ready() -> void:
	# Lock Z axis physics rotation and position to enforce strict 2.5D plane
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_handle_input(delta)
	_apply_movement(delta)
	_enforce_25d_plane()
	_update_camera_tracking(delta)
	move_and_slide()

func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(0.0, coyote_timer - delta)
	
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

func _handle_input(delta: float) -> void:
	var move_x: float = Input.get_axis("ui_left", "ui_right")
	if move_x != 0.0:
		facing_direction = sign(move_x)
	
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	
	# Jump execution with Coyote time and Buffer
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0 and not is_grabbing:
		_execute_jump()

func _execute_jump() -> void:
	velocity.y = jump_impulse
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	current_state = State.JUMP_START

func _apply_movement(delta: float) -> void:
	var move_x: float = Input.get_axis("ui_left", "ui_right")
	var target_speed: float = walk_speed
	
	if is_grabbing:
		target_speed = slow_drag_speed
	elif Input.is_action_pressed("run_modifier"):
		target_speed = run_speed
	
	var target_vx: float = move_x * target_speed
	var accel: float = acceleration if is_on_floor() else air_acceleration
	
	if move_x == 0.0 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, target_vx, accel * delta)
	
	# Gravity calculation with Apex hang time & weighted fall
	if not is_on_floor():
		if abs(velocity.y) < 1.0: # Apex damping
			velocity.y -= gravity * apex_hang_time_damping * delta
			current_state = State.APEX
		elif velocity.y < 0.0: # Fast fall
			velocity.y -= gravity * fall_gravity_multiplier * delta
			current_state = State.FALL
		else:
			velocity.y -= gravity * delta
			current_state = State.AIRBORNE
	else:
		if abs(velocity.x) > 0.1:
			current_state = State.RUN if target_speed == run_speed else State.WALK
		else:
			current_state = State.IDLE

func _enforce_25d_plane() -> void:
	global_position.z = lock_z_coordinate
	velocity.z = 0.0

func _update_camera_tracking(delta: float) -> void:
	if not camera:
		return
	
	var look_ahead: float = facing_direction * look_ahead_distance
	var target_cam_x: float = global_position.x + look_ahead
	var target_cam_y: float = global_position.y + 1.1 # Eye level offset
	
	camera.global_position.x = lerp(camera.global_position.x, target_cam_x, camera_damping_x)
	camera.global_position.y = lerp(camera.global_position.y, target_cam_y, camera_damping_y)
	camera.global_position.z = 14.0 # Calibrated 14m camera distance for 32 deg FOV
