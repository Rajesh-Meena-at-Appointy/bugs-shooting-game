extends RefCounted

# Extensions - Utility functions and extensions for common operations
class_name Extensions

# Vector3 extensions
static func vector3_random_range(min_val: Vector3, max_val: Vector3) -> Vector3:
    return Vector3(
        randf_range(min_val.x, max_val.x),
        randf_range(min_val.y, max_val.y),
        randf_range(min_val.z, max_val.z)
    )

static func vector3_random_unit() -> Vector3:
    var phi = randf() * TAU
    var costheta = randf() * 2.0 - 1.0
    var theta = acos(costheta)
    
    return Vector3(
        sin(theta) * cos(phi),
        sin(theta) * sin(phi),
        cos(theta)
    )

static func vector3_random_in_sphere(radius: float) -> Vector3:
    return vector3_random_unit() * randf() * radius

static func vector3_distance_2d(a: Vector3, b: Vector3) -> float:
    var diff = Vector2(a.x - b.x, a.z - b.z)
    return diff.length()

# Array extensions
static func array_shuffle(array: Array) -> Array:
    var shuffled = array.duplicate()
    for i in range(shuffled.size() - 1, 0, -1):
        var j = randi() % (i + 1)
        var temp = shuffled[i]
        shuffled[i] = shuffled[j]
        shuffled[j] = temp
    return shuffled

static func array_random_element(array: Array):
    if array.is_empty():
        return null
    return array[randi() % array.size()]

static func array_remove_element(array: Array, element) -> bool:
    var index = array.find(element)
    if index != -1:
        array.remove_at(index)
        return true
    return false

static func array_get_random_elements(array: Array, count: int) -> Array:
    var shuffled = array_shuffle(array)
    return shuffled.slice(0, min(count, shuffled.size()))

# String extensions
static func string_word_wrap(text: String, max_width: int) -> String:
    var words = text.split(" ")
    var lines: Array[String] = []
    var current_line = ""
    
    for word in words:
        if current_line.length() + word.length() + 1 <= max_width:
            if current_line != "":
                current_line += " "
            current_line += word
        else:
            if current_line != "":
                lines.append(current_line)
            current_line = word
    
    if current_line != "":
        lines.append(current_line)
    
    return "\n".join(lines)

static func string_truncate(text: String, max_length: int, suffix: String = "...") -> String:
    if text.length() <= max_length:
        return text
    return text.substr(0, max_length - suffix.length()) + suffix

static func string_to_snake_case(text: String) -> String:
    var result = ""
    for i in range(text.length()):
        var char = text[i]
        if char.to_upper() == char and char.to_lower() != char:
            if i > 0:
                result += "_"
            result += char.to_lower()
        else:
            result += char
    return result

# Math extensions
static func lerp_smooth(from: float, to: float, weight: float, delta: float) -> float:
    return from + (to - from) * (1.0 - exp(-weight * delta))

static func approach(current: float, target: float, delta: float) -> float:
    var difference = target - current
    if abs(difference) <= delta:
        return target
    return current + sign(difference) * delta

static func wrap_angle(angle: float) -> float:
    while angle > PI:
        angle -= TAU
    while angle < -PI:
        angle += TAU
    return angle

static func angle_difference(from: float, to: float) -> float:
    var difference = wrap_angle(to - from)
    return difference

static func smooth_damp_angle(current: float, target: float, velocity: float, smooth_time: float, delta: float) -> Dictionary:
    target = current + wrap_angle(target - current)
    var result = smooth_damp(current, target, velocity, smooth_time, delta)
    return {"value": result.value, "velocity": result.velocity}

static func smooth_damp(current: float, target: float, velocity: float, smooth_time: float, delta: float) -> Dictionary:
    smooth_time = max(0.0001, smooth_time)
    var omega = 2.0 / smooth_time
    var x = omega * delta
    var exp_val = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
    
    var change = current - target
    var temp = (velocity + omega * change) * delta
    velocity = (velocity - omega * temp) * exp_val
    var output = target + (change + temp) * exp_val
    
    return {"value": output, "velocity": velocity}

# Node extensions
static func find_child_by_type(node: Node, type: String) -> Node:
    if node.get_script() and node.get_script().get_global_name() == type:
        return node
    
    for child in node.get_children():
        var result = find_child_by_type(child, type)
        if result:
            return result
    
    return null

static func find_children_by_type(node: Node, type: String) -> Array[Node]:
    var results: Array[Node] = []
    _find_children_by_type_recursive(node, type, results)
    return results

static func _find_children_by_type_recursive(node: Node, type: String, results: Array[Node]):
    if node.get_script() and node.get_script().get_global_name() == type:
        results.append(node)
    
    for child in node.get_children():
        _find_children_by_type_recursive(child, type, results)

static func safe_connect(source: Object, signal_name: String, target: Object, method_name: String):
    if not source.is_connected(signal_name, Callable(target, method_name)):
        source.connect(signal_name, Callable(target, method_name))

static func safe_disconnect(source: Object, signal_name: String, target: Object, method_name: String):
    if source.is_connected(signal_name, Callable(target, method_name)):
        source.disconnect(signal_name, Callable(target, method_name))

# Timer utilities
static func create_timer(duration: float, callback: Callable, one_shot: bool = true) -> Timer:
    var timer = Timer.new()
    timer.wait_time = duration
    timer.one_shot = one_shot
    timer.timeout.connect(callback)
    return timer

static func delay_call(node: Node, duration: float, callback: Callable):
    var timer = create_timer(duration, callback)
    node.add_child(timer)
    timer.start()

# Tween utilities
static func tween_property_smooth(object: Object, property: String, target_value: Variant, duration: float, ease_type: Tween.EaseType = Tween.EASE_OUT) -> Tween:
    var tween = object.create_tween()
    tween.tween_property(object, property, target_value, duration)
    tween.set_ease(ease_type)
    return tween

static func tween_shake(object: Object, property: String, intensity: float, duration: float, frequency: float = 10.0) -> Tween:
    var tween = object.create_tween()
    var original_value = object.get(property)
    
    for i in range(int(duration * frequency)):
        var shake_offset = Vector3(
            randf_range(-intensity, intensity),
            randf_range(-intensity, intensity),
            randf_range(-intensity, intensity)
        )
        tween.tween_property(object, property, original_value + shake_offset, 1.0 / frequency)
    
    tween.tween_property(object, property, original_value, 0.1)
    return tween

# Color utilities
static func color_lerp_hsv(from: Color, to: Color, weight: float) -> Color:
    var from_hsv = rgb_to_hsv(from)
    var to_hsv = rgb_to_hsv(to)
    
    var lerped_hsv = Vector3(
        lerp_angle(from_hsv.x, to_hsv.x, weight),
        lerp(from_hsv.y, to_hsv.y, weight),
        lerp(from_hsv.z, to_hsv.z, weight)
    )
    
    return hsv_to_rgb(lerped_hsv)

static func rgb_to_hsv(color: Color) -> Vector3:
    var r = color.r
    var g = color.g
    var b = color.b
    
    var max_val = max(r, max(g, b))
    var min_val = min(r, min(g, b))
    var delta = max_val - min_val
    
    var h = 0.0
    var s = 0.0 if max_val == 0 else delta / max_val
    var v = max_val
    
    if delta != 0:
        if max_val == r:
            h = (g - b) / delta
        elif max_val == g:
            h = 2 + (b - r) / delta
        else:
            h = 4 + (r - g) / delta
        
        h *= 60
        if h < 0:
            h += 360
    
    return Vector3(h, s, v)

static func hsv_to_rgb(hsv: Vector3) -> Color:
    var h = hsv.x
    var s = hsv.y
    var v = hsv.z
    
    var c = v * s
    var x = c * (1 - abs(fmod(h / 60.0, 2) - 1))
    var m = v - c
    
    var r = 0.0
    var g = 0.0
    var b = 0.0
    
    if h < 60:
        r = c; g = x; b = 0
    elif h < 120:
        r = x; g = c; b = 0
    elif h < 180:
        r = 0; g = c; b = x
    elif h < 240:
        r = 0; g = x; b = c
    elif h < 300:
        r = x; g = 0; b = c
    else:
        r = c; g = 0; b = x
    
    return Color(r + m, g + m, b + m)

# File utilities
static func load_json_file(path: String) -> Dictionary:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return {}
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    
    if parse_result != OK:
        return {}
    
    return json.data

static func save_json_file(path: String, data: Dictionary) -> bool:
    var file = FileAccess.open(path, FileAccess.WRITE)
    if not file:
        return false
    
    var json_string = JSON.stringify(data)
    file.store_string(json_string)
    file.close()
    
    return true

# Debug utilities
static func print_node_tree(node: Node, indent: int = 0):
    var prefix = ""
    for i in indent:
        prefix += "  "
    
    print(prefix + node.name + " (" + node.get_class() + ")")
    
    for child in node.get_children():
        print_node_tree(child, indent + 1)

static func benchmark_function(callable: Callable, iterations: int = 1) -> float:
    var start_time = Engine.get_ticks_msec()
    
    for i in iterations:
        callable.call()
    
    var end_time = Engine.get_ticks_msec()
    return float(end_time - start_time) / 1000.0 / iterations