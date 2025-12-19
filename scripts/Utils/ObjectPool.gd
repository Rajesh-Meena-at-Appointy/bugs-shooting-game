extends Node

# Object Pool System for performance optimization
# Reduces garbage collection by reusing objects

# Pool containers
var pools: Dictionary = {}

# Pool statistics
var pool_stats: Dictionary = {}

func _ready():
	# Set up as singleton
	if not get_tree().has_meta("ObjectPool"):
		get_tree().set_meta("ObjectPool", self)

# Create a new pool for a specific object type
func create_pool(pool_name: String, scene_path: String, initial_size: int = 10, max_size: int = 50):
	if pools.has(pool_name):
		print("Pool already exists: ", pool_name)
		return false
	
	var new_pool = {
		"scene_path": scene_path,
		"available": [],
		"in_use": [],
		"max_size": max_size,
		"scene_reference": null
	}
	
	# Load scene reference
	if ResourceLoader.exists(scene_path):
		new_pool.scene_reference = load(scene_path)
	else:
		print("Scene not found: ", scene_path)
		return false
	
	pools[pool_name] = new_pool
	
	# Initialize statistics
	pool_stats[pool_name] = {
		"created": 0,
		"reused": 0,
		"peak_usage": 0,
		"current_usage": 0
	}
	
	# Pre-populate pool
	for i in initial_size:
		create_and_store_object(pool_name)
	
	print("Created pool: ", pool_name, " with ", initial_size, " objects")
	return true

# Get an object from the pool
func get_object(pool_name: String) -> Node:
	if not pools.has(pool_name):
		print("Pool not found: ", pool_name)
		return null
	
	var pool = pools[pool_name]
	var stats = pool_stats[pool_name]
	var object: Node = null
	
	# Try to reuse an available object
	if pool.available.size() > 0:
		object = pool.available.pop_back()
		stats.reused += 1
	else:
		# Create new object if pool not at max capacity
		if pool.in_use.size() < pool.max_size:
			object = create_new_object(pool_name)
			stats.created += 1
		else:
			print("Pool at max capacity: ", pool_name)
			return null
	
	if object:
		# Move to in_use array
		pool.in_use.append(object)
		stats.current_usage = pool.in_use.size()
		stats.peak_usage = max(stats.peak_usage, stats.current_usage)
		
		# Reset object state
		reset_object(object)
		
		# Add to scene if needed
		if object.get_parent() == null:
			get_tree().current_scene.add_child(object)
	
	return object

# Return an object to the pool
func return_object(pool_name: String, object: Node) -> bool:
	if not pools.has(pool_name):
		print("Pool not found: ", pool_name)
		return false
	
	var pool = pools[pool_name]
	var stats = pool_stats[pool_name]
	
	# Find and remove from in_use
	var index = pool.in_use.find(object)
	if index == -1:
		print("Object not found in pool: ", pool_name)
		return false
	
	pool.in_use.remove_at(index)
	
	# Deactivate object
	deactivate_object(object)
	
	# Move to available pool
	pool.available.append(object)
	stats.current_usage = pool.in_use.size()
	
	return true

# Create and store a new object without activating it
func create_and_store_object(pool_name: String):
	if not pools.has(pool_name):
		return
	
	var pool = pools[pool_name]
	
	if pool.scene_reference:
		var new_object = pool.scene_reference.instantiate()
		deactivate_object(new_object)
		pool.available.append(new_object)

# Create a new object instance
func create_new_object(pool_name: String) -> Node:
	if not pools.has(pool_name):
		return null
	
	var pool = pools[pool_name]
	
	if pool.scene_reference:
		return pool.scene_reference.instantiate()
	
	return null

# Reset object to default state
func reset_object(object: Node):
	if object == null:
		return
	
	# Remove from current parent
	if object.get_parent():
		object.get_parent().remove_child(object)
	
	# Reset common properties
	if object.has_method("reset_for_pool"):
		object.reset_for_pool()
	else:
		# Default reset behavior
		object.position = Vector3.ZERO
		object.rotation = Vector3.ZERO
		object.scale = Vector3.ONE
		
		# Reset visibility and collision
		object.visible = true
		
		if object.has_method("set_collision_layer"):
			object.collision_layer = 1
		
		if object.has_method("set_collision_mask"):
			object.collision_mask = 1
	
	# Reset modulation
	object.modulate = Color.WHITE

# Deactivate object (hide and remove from scene)
func deactivate_object(object: Node):
	if object == null:
		return
	
	# Remove from scene
	if object.get_parent():
		object.get_parent().remove_child(object)
	
	# Hide object
	object.visible = false
	
	# Custom deactivation
	if object.has_method("deactivate_for_pool"):
		object.deactivate_for_pool()

# Clear a pool completely
func clear_pool(pool_name: String):
	if not pools.has(pool_name):
		return
	
	var pool = pools[pool_name]
	
	# Free all objects
	for object in pool.available:
		if is_instance_valid(object):
			object.queue_free()
	
	for object in pool.in_use:
		if is_instance_valid(object):
			object.queue_free()
	
	# Clear arrays
	pool.available.clear()
	pool.in_use.clear()
	
	# Reset stats
	pool_stats[pool_name] = {
		"created": 0,
		"reused": 0,
		"peak_usage": 0,
		"current_usage": 0
	}

# Get pool statistics
func get_pool_stats(pool_name: String) -> Dictionary:
	if pool_stats.has(pool_name):
		return pool_stats[pool_name].duplicate()
	return {}

# Get all pools info
func get_all_pool_info() -> Dictionary:
	var info = {}
	
	for pool_name in pools.keys():
		var pool = pools[pool_name]
		var stats = pool_stats[pool_name]
		
		info[pool_name] = {
			"available": pool.available.size(),
			"in_use": pool.in_use.size(),
			"max_size": pool.max_size,
			"stats": stats.duplicate()
		}
	
	return info

# Cleanup unused objects in pools
func cleanup_pools():
	for pool_name in pools.keys():
		var pool = pools[pool_name]
		
		# Remove invalid objects
		var valid_available = []
		for object in pool.available:
			if is_instance_valid(object):
				valid_available.append(object)
			
		var valid_in_use = []
		for object in pool.in_use:
			if is_instance_valid(object):
				valid_in_use.append(object)
		
		pool.available = valid_available
		pool.in_use = valid_in_use
		
		# Update current usage
		pool_stats[pool_name].current_usage = pool.in_use.size()

# Auto-return objects that have been marked for return
func auto_return_marked_objects():
	for pool_name in pools.keys():
		var pool = pools[pool_name]
		var objects_to_return = []
		
		for object in pool.in_use:
			if object.has_method("is_ready_for_return") and object.is_ready_for_return():
				objects_to_return.append(object)
		
		# Return the marked objects
		for object in objects_to_return:
			return_object(pool_name, object)

func _process(_delta):
	# Periodic cleanup and auto-return
	cleanup_pools()
	auto_return_marked_objects()

# Debug function to print pool status
func print_pool_status():
	print("=== Object Pool Status ===")
	for pool_name in pools.keys():
		var pool = pools[pool_name]
		var stats = pool_stats[pool_name]
		
		print("%s: Available: %d, In Use: %d, Max: %d" % [
			pool_name,
			pool.available.size(),
			pool.in_use.size(),
			pool.max_size
		])
		print("  Stats - Created: %d, Reused: %d, Peak: %d" % [
			stats.created,
			stats.reused,
			stats.peak_usage
		])

# Static access function
static func instance():
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		return tree.get_meta("ObjectPool", null)
	return null
