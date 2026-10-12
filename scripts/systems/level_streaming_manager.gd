# ==============================================================================
# ZERO-LOADING-SCREEN SEAMLESS LEVEL STREAMING MANAGER FOR GODOT 4.x
# Reverse-Engineered from Playdead's SubsceneBounds & UnloadInactiveSubscenes
# ==============================================================================
class_name InsideLevelStreamingManager
extends Node

signal subscene_loaded(subscene_name: String)
signal subscene_unloaded(subscene_name: String)

@export_group("Player Tracking")
@export var player_node_path: NodePath
@export var update_frequency_sec: float = 0.5

@export_group("Streaming Distance Thresholds")
@export var preload_distance_x: float = 35.0       # Distance ahead to start background loading (m)
@export var unload_distance_x: float = 55.0        # Distance behind to free from memory (m)

@export_group("Subscene Definitions")
# Array of dictionaries:
# [{"name": "Forest_01", "bounds_min_x": -50.0, "bounds_max_x": 50.0, "scene_path": "res://subscenes/forest_01.tscn"}]
@export var subscene_registry: Array[Dictionary] = []

# Runtime caches
var player_node: Node3D = null
var active_subscene_instances: Dictionary = {} # subscene_name -> Node
var pending_loads: Dictionary = {}             # subscene_name -> ResourceInteractiveLoader
var update_timer: float = 0.0

func _ready() -> void:
	player_node = get_node_or_null(player_node_path) as Node3D

func _process(delta: float) -> void:
	update_timer += delta
	if update_timer >= update_frequency_sec:
		update_timer = 0.0
		_evaluate_subscene_stream()
		
	_process_background_loading()

func _evaluate_subscene_stream() -> void:
	if not player_node:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_node = players[0]
		else:
			return
			
	var p_x = player_node.global_position.x
	
	for entry in subscene_registry:
		var s_name = entry.get("name", "")
		var min_x = entry.get("bounds_min_x", 0.0)
		var max_x = entry.get("bounds_max_x", 0.0)
		var sc_path = entry.get("scene_path", "")
		
		# Distance to subscene boundary
		var dist_to_subscene = 0.0
		if p_x < min_x:
			dist_to_subscene = min_x - p_x
		elif p_x > max_x:
			dist_to_subscene = p_x - max_x
		else:
			dist_to_subscene = 0.0 # Inside subscene
			
		# Should this subscene be loaded?
		if dist_to_subscene <= preload_distance_x:
			if not active_subscene_instances.has(s_name) and not pending_loads.has(s_name):
				_start_background_load(s_name, sc_path)
		# Should this subscene be unloaded?
		elif dist_to_subscene >= unload_distance_x:
			if active_subscene_instances.has(s_name):
				_unload_subscene(s_name)

func _start_background_load(s_name: String, sc_path: String) -> void:
	if ResourceLoader.exists(sc_path):
		ResourceLoader.load_threaded_request(sc_path)
		pending_loads[s_name] = sc_path

func _process_background_loading() -> void:
	var completed: Array[String] = []
	
	for s_name in pending_loads.keys():
		var sc_path = pending_loads[s_name]
		var status = ResourceLoader.load_threaded_get_status(sc_path)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed_scene = ResourceLoader.load_threaded_get(sc_path) as PackedScene
			if packed_scene:
				var instance = packed_scene.instantiate()
				add_child(instance)
				active_subscene_instances[s_name] = instance
				emit_signal("subscene_loaded", s_name)
			completed.append(s_name)
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			completed.append(s_name)
			
	for s_name in completed:
		pending_loads.erase(s_name)

func _unload_subscene(s_name: String) -> void:
	if active_subscene_instances.has(s_name):
		var instance = active_subscene_instances[s_name] as Node
		if instance and is_instance_valid(instance):
			instance.queue_free()
		active_subscene_instances.erase(s_name)
		emit_signal("subscene_unloaded", s_name)
