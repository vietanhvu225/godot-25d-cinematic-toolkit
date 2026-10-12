# ==============================================================================
# CINEMATIC CAMERA FRAMING TRIGGER (BLEND BOX) FOR GODOT 4.x
# Reverse-Engineered from Playdead's Camera Blend Box & EndLockCameraPivot
# ==============================================================================
class_name InsideCinematicCameraTrigger
extends Area3D

signal camera_framing_entered(trigger: InsideCinematicCameraTrigger)
signal camera_framing_exited(trigger: InsideCinematicCameraTrigger)

@export_group("Target Framing Parameters")
@export var target_fov: float = 32.0               # Target camera FOV (degrees)
@export var target_z_distance: float = 14.0        # Target camera depth distance (meters)
@export var target_offset_y: float = 1.1           # Target vertical framing height (meters)
@export var override_look_ahead: bool = false
@export var target_look_ahead: float = 2.5
@export var lock_camera_x: bool = false            # Freeze horizontal tracking (stationary shot)
@export var lock_camera_y: bool = false            # Freeze vertical tracking

@export_group("Transition Blending")
@export var transition_duration: float = 1.8       # Blend duration in seconds
@export var transition_curve: TransitionType = TransitionType.TRANS_CUBIC

enum TransitionType {
	TRANS_LINEAR,
	TRANS_SINE,
	TRANS_CUBIC,
	TRANS_QUAD
}

# Active status
var is_player_inside: bool = false
var blend_progress: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body is CharacterBody3D:
		is_player_inside = true
		emit_signal("camera_framing_entered", self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body is CharacterBody3D:
		is_player_inside = false
		emit_signal("camera_framing_exited", self)
