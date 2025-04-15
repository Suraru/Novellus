extends Node2D

# Reference to the character data
var character_data = {}

# Base sizes and positions
var head_center = Vector2(200, 150)
var head_size = Vector2(150, 180)

# Colors
var skin_color = Color(0.9, 0.8, 0.7)
var hair_color = Color(0.3, 0.2, 0.1)
var eye_color = Color(0.2, 0.5, 0.8)

func _ready():
	# Initialize with default position if needed
	if head_center == Vector2(400, 300):  # If still at default values
		head_center = Vector2(200, 150)  # Adjust based on your container
		head_size = Vector2(150, 180)    # Slightly smaller for the preview

# Add this method to handle resizing
func set_preview_size(container_size):
	# Adjust head center to be in the center of the container
	head_center = Vector2(container_size.x / 2, container_size.y / 2)
	# Adjust head size based on container size
	head_size = Vector2(
		min(container_size.x, container_size.y) * 0.5,
		min(container_size.x, container_size.y) * 0.6
	)
	queue_redraw()

# Load character data from file
func load_character(file_path):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json_result = JSON.parse_string(json_string)
		if json_result:
			character_data = json_result
			queue_redraw()
			return true
	return false

# Main drawing function
func _draw():
	if not character_data.has("appearance"):
		return
		
	# Draw body parts in order from back to front
	draw_neck()
	draw_ears()
	draw_head()
	draw_eyes()
	draw_nose()
	draw_mouth()
	draw_chin()

# Draw head based on type and scale
func draw_head():
	var head_data = character_data["appearance"].get("head", {"type": 0, "scale": 1.0})
	var head_type = head_data["type"]
	var head_scale = head_data["scale"]
	
	# Scale the head size
	var scaled_size = Vector2(head_size.x * head_scale, head_size.y * head_scale)
	
	match head_type:
		0: # Round
			draw_circle(head_center, scaled_size.x/2, skin_color)
		1: # Square
			var rect = Rect2(
				head_center.x - scaled_size.x/2,
				head_center.y - scaled_size.y/2,
				scaled_size.x,
				scaled_size.y
			)
			draw_rect(rect, skin_color)
		2: # Oval
			draw_ellipse(head_center, scaled_size/2, skin_color)
		3: # Heart
			draw_heart_shape(head_center, scaled_size, skin_color)
		4: # Long
			draw_ellipse(head_center, Vector2(scaled_size.x/2.5, scaled_size.y/2), skin_color)
		5: # Diamond
			draw_diamond_shape(head_center, scaled_size, skin_color)
		6: # Triangle
			draw_triangle_shape(head_center, scaled_size, skin_color)
		7: # Rectangle
			var rect = Rect2(
				head_center.x - scaled_size.x/2,
				head_center.y - scaled_size.y/2,
				scaled_size.x,
				scaled_size.y * 1.2
			)
			draw_rect(rect, skin_color)
		_: # Default to round
			draw_circle(head_center, scaled_size.x/2, skin_color)

# Draw eyes based on type and scale
func draw_eyes():
	var eyes_data = character_data["appearance"].get("eyes", {"type": 0, "scale": 1.0})
	var eyes_type = eyes_data["type"]
	var eyes_scale = eyes_data["scale"]
	
	# Base eye positions and size
	var eye_size = Vector2(30, 20) * eyes_scale
	var eye_spacing = 50 * eyes_scale
	var left_eye_pos = Vector2(head_center.x - eye_spacing, head_center.y - 20)
	var right_eye_pos = Vector2(head_center.x + eye_spacing, head_center.y - 20)
	
	match eyes_type:
		0: # Round
			draw_circle(left_eye_pos, eye_size.x/2, Color.WHITE)
			draw_circle(right_eye_pos, eye_size.x/2, Color.WHITE)
			draw_circle(left_eye_pos, eye_size.x/4, eye_color)
			draw_circle(right_eye_pos, eye_size.x/4, eye_color)
		1: # Almond
			draw_almond_shape(left_eye_pos, eye_size, Color.WHITE)
			draw_almond_shape(right_eye_pos, eye_size, Color.WHITE)
			draw_circle(left_eye_pos, eye_size.x/4, eye_color)
			draw_circle(right_eye_pos, eye_size.x/4, eye_color)
		2: # Narrow
			draw_ellipse(left_eye_pos, Vector2(eye_size.x/2, eye_size.y/4), Color.WHITE)
			draw_ellipse(right_eye_pos, Vector2(eye_size.x/2, eye_size.y/4), Color.WHITE)
			draw_ellipse(left_eye_pos, Vector2(eye_size.x/4, eye_size.y/6), eye_color)
			draw_ellipse(right_eye_pos, Vector2(eye_size.x/4, eye_size.y/6), eye_color)
		3: # Wide
			draw_ellipse(left_eye_pos, Vector2(eye_size.x/1.5, eye_size.y/2), Color.WHITE)
			draw_ellipse(right_eye_pos, Vector2(eye_size.x/1.5, eye_size.y/2), Color.WHITE)
			draw_circle(left_eye_pos, eye_size.x/3, eye_color)
			draw_circle(right_eye_pos, eye_size.x/3, eye_color)
		4: # Downturned
			draw_downturned_shape(left_eye_pos, eye_size, Color.WHITE)
			draw_downturned_shape(right_eye_pos, eye_size, Color.WHITE)
			draw_circle(left_eye_pos, eye_size.x/4, eye_color)
			draw_circle(right_eye_pos, eye_size.x/4, eye_color)
		5: # Upturned
			draw_upturned_shape(left_eye_pos, eye_size, Color.WHITE)
			draw_upturned_shape(right_eye_pos, eye_size, Color.WHITE)
			draw_circle(left_eye_pos, eye_size.x/4, eye_color)
			draw_circle(right_eye_pos, eye_size.x/4, eye_color)
		6: # Hooded
			draw_hooded_shape(left_eye_pos, eye_size, Color.WHITE)
			draw_hooded_shape(right_eye_pos, eye_size, Color.WHITE)
			draw_circle(left_eye_pos, eye_size.x/4, eye_color)
			draw_circle(right_eye_pos, eye_size.x/4, eye_color)
		7: # Deep-set
			draw_deepset_shape(left_eye_pos, eye_size, Color.WHITE)
			draw_deepset_shape(right_eye_pos, eye_size, Color.WHITE)
			draw_circle(left_eye_pos, eye_size.x/4, eye_color)
			draw_circle(right_eye_pos, eye_size.x/4, eye_color)
		_: # Default to round
			draw_circle(left_eye_pos, eye_size.x/2, Color.WHITE)
			draw_circle(right_eye_pos, eye_size.x/2, Color.WHITE)
			draw_circle(left_eye_pos, eye_size.x/4, eye_color)
			draw_circle(right_eye_pos, eye_size.x/4, eye_color)

# Draw ears based on type and scale
func draw_ears():
	var ears_data = character_data["appearance"].get("ears", {"type": 0, "scale": 1.0})
	var ears_type = ears_data["type"]
	var ears_scale = ears_data["scale"]
	
	# Base ear positions and size
	var ear_size = Vector2(25, 40) * ears_scale
	var head_width = head_size.x * character_data["appearance"].get("head", {"scale": 1.0})["scale"]
	var left_ear_pos = Vector2(head_center.x - head_width/2 - 5, head_center.y - 20)
	var right_ear_pos = Vector2(head_center.x + head_width/2 + 5, head_center.y - 20)
	
	match ears_type:
		0: # Round
			draw_round_ear(left_ear_pos, ear_size, skin_color)
			draw_round_ear(right_ear_pos, ear_size, skin_color)
		1: # Pointed
			draw_pointed_ear(left_ear_pos, ear_size, skin_color)
			draw_pointed_ear(right_ear_pos, ear_size, skin_color)
		2: # Small
			draw_round_ear(left_ear_pos, ear_size * 0.7, skin_color)
			draw_round_ear(right_ear_pos, ear_size * 0.7, skin_color)
		3: # Large
			draw_round_ear(left_ear_pos, ear_size * 1.3, skin_color)
			draw_round_ear(right_ear_pos, ear_size * 1.3, skin_color)
		4: # Flat
			draw_flat_ear(left_ear_pos, ear_size, skin_color)
			draw_flat_ear(right_ear_pos, ear_size, skin_color)
		5: # Protruding
			draw_protruding_ear(left_ear_pos, ear_size, skin_color)
			draw_protruding_ear(right_ear_pos, ear_size, skin_color)
		6: # Attached
			draw_attached_ear(left_ear_pos, ear_size, skin_color)
			draw_attached_ear(right_ear_pos, ear_size, skin_color)
		7: # Free
			draw_free_ear(left_ear_pos, ear_size, skin_color)
			draw_free_ear(right_ear_pos, ear_size, skin_color)
		_: # Default to round
			draw_round_ear(left_ear_pos, ear_size, skin_color)
			draw_round_ear(right_ear_pos, ear_size, skin_color)

# Draw nose based on type and scale
func draw_nose():
	var nose_data = character_data["appearance"].get("nose", {"type": 0, "scale": 1.0})
	var nose_type = nose_data["type"] 
	var nose_scale = nose_data["scale"]
	
	# Base nose position and size
	var nose_size = Vector2(30, 40) * nose_scale
	var nose_pos = Vector2(head_center.x, head_center.y + 20)
	
	match nose_type:
		0: # Straight
			draw_straight_nose(nose_pos, nose_size, skin_color.darkened(0.1))
		1: # Roman
			draw_roman_nose(nose_pos, nose_size, skin_color.darkened(0.1))
		2: # Button
			draw_button_nose(nose_pos, nose_size, skin_color.darkened(0.1))
		3: # Aquiline
			draw_aquiline_nose(nose_pos, nose_size, skin_color.darkened(0.1))
		4: # Snub
			draw_snub_nose(nose_pos, nose_size, skin_color.darkened(0.1))
		5: # Greek
			draw_greek_nose(nose_pos, nose_size, skin_color.darkened(0.1))
		6: # Nubian
			draw_nubian_nose(nose_pos, nose_size, skin_color.darkened(0.1))
		7: # Hawk
			draw_hawk_nose(nose_pos, nose_size, skin_color.darkened(0.1))
		_: # Default to straight
			draw_straight_nose(nose_pos, nose_size, skin_color.darkened(0.1))

# Draw mouth based on type and scale
func draw_mouth():
	var mouth_data = character_data["appearance"].get("mouth", {"type": 0, "scale": 1.0})
	var mouth_type = mouth_data["type"]
	var mouth_scale = mouth_data["scale"]
	
	# Base mouth position and size
	var mouth_size = Vector2(60, 20) * mouth_scale
	var mouth_pos = Vector2(head_center.x, head_center.y + 70)
	
	match mouth_type:
		0: # Full
			draw_full_mouth(mouth_pos, mouth_size, Color(0.8, 0.2, 0.2))
		1: # Thin
			draw_thin_mouth(mouth_pos, mouth_size, Color(0.8, 0.2, 0.2))
		2: # Wide
			draw_wide_mouth(mouth_pos, mouth_size, Color(0.8, 0.2, 0.2))
		3: # Heart
			draw_heart_mouth(mouth_pos, mouth_size, Color(0.8, 0.2, 0.2))
		4: # Bow
			draw_bow_mouth(mouth_pos, mouth_size, Color(0.8, 0.2, 0.2))
		5: # Straight
			draw_straight_mouth(mouth_pos, mouth_size, Color(0.8, 0.2, 0.2))
		6: # Round
			draw_round_mouth(mouth_pos, mouth_size, Color(0.8, 0.2, 0.2))
		7: # Downturned
			draw_downturned_mouth(mouth_pos, mouth_size, Color(0.8, 0.2, 0.2))
		_: # Default to full
			draw_full_mouth(mouth_pos, mouth_size, Color(0.8, 0.2, 0.2))

# Draw chin based on type and scale
func draw_chin():
	var chin_data = character_data["appearance"].get("chin", {"type": 0, "scale": 1.0})
	var chin_type = chin_data["type"]
	var chin_scale = chin_data["scale"]
	
	# Base chin position and size
	var chin_size = Vector2(60, 40) * chin_scale
	var chin_pos = Vector2(head_center.x, head_center.y + 120)
	
	match chin_type:
		0: # Round
			draw_round_chin(chin_pos, chin_size, skin_color)
		1: # Square
			draw_square_chin(chin_pos, chin_size, skin_color)
		2: # Pointed
			draw_pointed_chin(chin_pos, chin_size, skin_color)
		3: # Cleft
			draw_cleft_chin(chin_pos, chin_size, skin_color)
		4: # Dimpled
			draw_dimpled_chin(chin_pos, chin_size, skin_color)
		5: # Receding
			draw_receding_chin(chin_pos, chin_size, skin_color)
		6: # Protruding
			draw_protruding_chin(chin_pos, chin_size, skin_color)
		7: # Double
			draw_double_chin(chin_pos, chin_size, skin_color)
		_: # Default to round
			draw_round_chin(chin_pos, chin_size, skin_color)

# Draw neck based on type and scale
func draw_neck():
	var neck_data = character_data["appearance"].get("neck", {"type": 0, "scale": 1.0})
	var neck_type = neck_data["type"]
	var neck_scale = neck_data["scale"]
	
	# Base neck position and size
	var neck_size = Vector2(50, 80) * neck_scale
	var neck_pos = Vector2(head_center.x, head_center.y + 160)
	
	match neck_type:
		0: # Short
			draw_short_neck(neck_pos, neck_size, skin_color)
		1: # Long
			draw_long_neck(neck_pos, neck_size, skin_color)
		2: # Thick
			draw_thick_neck(neck_pos, neck_size, skin_color)
		3: # Thin
			draw_thin_neck(neck_pos, neck_size, skin_color)
		4: # Average
			draw_average_neck(neck_pos, neck_size, skin_color)
		5: # Muscular
			draw_muscular_neck(neck_pos, neck_size, skin_color)
		6: # Slender
			draw_slender_neck(neck_pos, neck_size, skin_color)
		7: # Broad
			draw_broad_neck(neck_pos, neck_size, skin_color)
		_: # Default to average
			draw_average_neck(neck_pos, neck_size, skin_color)

# --- Helper drawing functions ---

# Custom shape drawing functions
func draw_ellipse(center, half_size, color):
	var points = PackedVector2Array()
	for i in range(32):
		var angle = i * TAU / 32
		var point = center + Vector2(cos(angle) * half_size.x, sin(angle) * half_size.y)
		points.push_back(point)
	draw_colored_polygon(points, color)

func draw_heart_shape(center, size, color):
	var points = PackedVector2Array()
	for i in range(32):
		var angle = i * TAU / 32
		var x = sin(angle) * cos(angle) * size.x / 2
		var y = -(13 * cos(angle) - 5 * cos(2*angle) - 2 * cos(3*angle) - cos(4*angle)) * size.y / 24
		points.push_back(center + Vector2(x, y))
	draw_colored_polygon(points, color)

func draw_diamond_shape(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(0, -size.y/2),
		center + Vector2(size.x/2, 0),
		center + Vector2(0, size.y/2),
		center + Vector2(-size.x/2, 0)
	])
	draw_colored_polygon(points, color)

func draw_triangle_shape(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(0, -size.y/2),
		center + Vector2(size.x/2, size.y/2),
		center + Vector2(-size.x/2, size.y/2)
	])
	draw_colored_polygon(points, color)

# Eye shapes
func draw_almond_shape(center, size, color):
	var points = PackedVector2Array()
	for i in range(32):
		var angle = i * TAU / 32
		var x = cos(angle) * size.x / 2
		var y = sin(angle) * size.y / 2
		if abs(x) > size.x / 4:
			y *= 0.7
		points.push_back(center + Vector2(x, y))
	draw_colored_polygon(points, color)

func draw_downturned_shape(center, size, color):
	var points = PackedVector2Array()
	for i in range(32):
		var angle = i * TAU / 32
		var x = cos(angle) * size.x / 2
		var y = sin(angle) * size.y / 2
		if x > 0:
			y += x * 0.3
		else:
			y -= x * 0.3
		points.push_back(center + Vector2(x, y))
	draw_colored_polygon(points, color)

func draw_upturned_shape(center, size, color):
	var points = PackedVector2Array()
	for i in range(32):
		var angle = i * TAU / 32
		var x = cos(angle) * size.x / 2
		var y = sin(angle) * size.y / 2
		if x > 0:
			y -= x * 0.3
		else:
			y += x * 0.3
		points.push_back(center + Vector2(x, y))
	draw_colored_polygon(points, color)

func draw_hooded_shape(center, size, color):
	draw_ellipse(center, size/2, color)
	draw_arc(center + Vector2(0, -size.y/4), size.x/2, -PI, 0, 16, skin_color, 5)

func draw_deepset_shape(center, size, color):
	draw_ellipse(center, size/2, color)
	draw_arc(center + Vector2(0, -size.y/3), size.x/1.8, -PI, 0, 16, skin_color.darkened(0.1), 5)

# Ear shapes
func draw_round_ear(center, size, color):
	draw_ellipse(center, size/2, color)
	draw_ellipse(center, Vector2(size.x * 0.3, size.y * 0.3)/2, color.darkened(0.1))

func draw_pointed_ear(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(-size.x/2, size.y/2),
		center + Vector2(0, -size.y/2),
		center + Vector2(size.x/2, size.y/2)
	])
	draw_colored_polygon(points, color)
	
	var inner_points = PackedVector2Array([
		center + Vector2(-size.x/4, size.y/4),
		center + Vector2(0, -size.y/4),
		center + Vector2(size.x/4, size.y/4)
	])
	draw_colored_polygon(inner_points, color.darkened(0.1))

func draw_flat_ear(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(-size.x/2, -size.y/2),
		center + Vector2(-size.x/4, -size.y/2),
		center + Vector2(size.x/4, -size.y/2),
		center + Vector2(size.x/2, -size.y/2),
		center + Vector2(size.x/2, size.y/2),
		center + Vector2(-size.x/2, size.y/2)
	])
	draw_colored_polygon(points, color)

func draw_protruding_ear(center, size, color):
	draw_ellipse(center + Vector2(size.x * 0.3, 0), Vector2(size.x * 0.7, size.y)/2, color)
	draw_ellipse(center + Vector2(size.x * 0.3, 0), Vector2(size.x * 0.4, size.y * 0.6)/2, color.darkened(0.1))

func draw_attached_ear(center, size, color):
	draw_rect(Rect2(center.x - size.x/2, center.y - size.y/2, size.x, size.y), color)

func draw_free_ear(center, size, color):
	draw_ellipse(center, size/2, color)
	draw_ellipse(center, Vector2(size.x * 0.6, size.y * 0.6)/2, color.darkened(0.1))

# Nose shapes
func draw_straight_nose(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(-size.x/4, -size.y/2),
		center + Vector2(size.x/4, -size.y/2),
		center + Vector2(size.x/2, size.y/2),
		center + Vector2(-size.x/2, size.y/2)
	])
	draw_colored_polygon(points, color)
	
	# Nostrils
	draw_circle(center + Vector2(-size.x/4, size.y/3), size.x/8, color.darkened(0.2))
	draw_circle(center + Vector2(size.x/4, size.y/3), size.x/8, color.darkened(0.2))

func draw_roman_nose(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(-size.x/4, -size.y/2),
		center + Vector2(size.x/4, -size.y/2),
		center + Vector2(size.x/3, -size.y/4),
		center + Vector2(size.x/2, size.y/2),
		center + Vector2(-size.x/2, size.y/2)
	])
	draw_colored_polygon(points, color)
	
	# Nostrils
	draw_circle(center + Vector2(-size.x/4, size.y/3), size.x/8, color.darkened(0.2))
	draw_circle(center + Vector2(size.x/4, size.y/3), size.x/8, color.darkened(0.2))

func draw_button_nose(center, size, color):
	draw_circle(center, size.x/2, color)
	
	# Nostrils
	draw_circle(center + Vector2(-size.x/4, size.y/6), size.x/6, color.darkened(0.2))
	draw_circle(center + Vector2(size.x/4, size.y/6), size.x/6, color.darkened(0.2))

func draw_aquiline_nose(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(-size.x/4, -size.y/2),
		center + Vector2(size.x/4, -size.y/2),
		center + Vector2(size.x/2, -size.y/6),
		center + Vector2(size.x/3, size.y/6),
		center + Vector2(size.x/2, size.y/2),
		center + Vector2(-size.x/2, size.y/2)
	])
	draw_colored_polygon(points, color)
	
	# Nostrils
	draw_circle(center + Vector2(-size.x/4, size.y/3), size.x/8, color.darkened(0.2))
	draw_circle(center + Vector2(size.x/4, size.y/3), size.x/8, color.darkened(0.2))

func draw_snub_nose(center, size, color):
	draw_circle(center + Vector2(0, -size.y/6), size.x/3, color)
	
	# Nostrils
	draw_circle(center + Vector2(-size.x/4, 0), size.x/5, color.darkened(0.2))
	draw_circle(center + Vector2(size.x/4, 0), size.x/5, color.darkened(0.2))

func draw_greek_nose(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(-size.x/4, -size.y/2),
		center + Vector2(size.x/4, -size.y/2),
		center + Vector2(size.x/4, 0),
		center + Vector2(size.x/2, size.y/2),
		center + Vector2(-size.x/2, size.y/2),
		center + Vector2(-size.x/4, 0)
	])
	draw_colored_polygon(points, color)
	
	# Nostrils
	draw_circle(center + Vector2(-size.x/4, size.y/3), size.x/8, color.darkened(0.2))
	draw_circle(center + Vector2(size.x/4, size.y/3), size.x/8, color.darkened(0.2))

func draw_nubian_nose(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(-size.x/4, -size.y/2),
		center + Vector2(size.x/4, -size.y/2),
		center + Vector2(size.x/2, 0),
		center + Vector2(size.x/2, size.y/2),
		center + Vector2(-size.x/2, size.y/2),
		center + Vector2(-size.x/2, 0)
	])
	draw_colored_polygon(points, color)
	
	# Nostrils
	draw_circle(center + Vector2(-size.x/4, size.y/3), size.x/6, color.darkened(0.2))
	draw_circle(center + Vector2(size.x/4, size.y/3), size.x/6, color.darkened(0.2))

func draw_hawk_nose(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(-size.x/4, -size.y/2),
		center + Vector2(size.x/4, -size.y/2),
		center + Vector2(size.x/2, -size.y/4),
		center + Vector2(size.x/4, 0),
		center + Vector2(size.x/2, size.y/2),
		center + Vector2(-size.x/2, size.y/2),
		center + Vector2(-size.x/4, 0),
		center + Vector2(-size.x/2, -size.y/4)
	])
	draw_colored_polygon(points, color)
	
	# Nostrils
	draw_circle(center + Vector2(-size.x/4, size.y/3), size.x/8, color.darkened(0.2))
	draw_circle(center + Vector2(size.x/4, size.y/3), size.x/8, color.darkened(0.2))

# Mouth shapes
func draw_full_mouth(center, size, color):
	draw_ellipse(center, size/2, color)
	draw_ellipse(center + Vector2(0, -size.y*0.2), Vector2(size.x*0.8, size.y*0.4)/2, Color(0.7, 0.1, 0.1))

func draw_thin_mouth(center, size, color):
	draw_ellipse(center, Vector2(size.x, size.y*0.5)/2, color)
	draw_line(center + Vector2(-size.x/2, 0), center + Vector2(size.x/2, 0), Color(0.7, 0.1, 0.1), 2)

# Mouth shapes (continued)
func draw_wide_mouth(center, size, color):
	draw_ellipse(center, Vector2(size.x*1.3, size.y*0.7)/2, color)
	draw_ellipse(center + Vector2(0, -size.y*0.1), Vector2(size.x*1.1, size.y*0.4)/2, Color(0.7, 0.1, 0.1))

func draw_heart_mouth(center, size, color):
	var points = PackedVector2Array()
	for i in range(32):
		var angle = i * TAU / 32
		var x = sin(angle) * cos(angle) * size.x / 2
		var y = -(13 * cos(angle) - 5 * cos(2*angle) - 2 * cos(3*angle) - cos(4*angle)) * size.y / 32
		points.push_back(center + Vector2(x, y))
	draw_colored_polygon(points, color)
	
	# Inner lips
	var inner_points = PackedVector2Array()
	for i in range(32):
		var angle = i * TAU / 32
		var x = sin(angle) * cos(angle) * size.x * 0.4
		var y = -(13 * cos(angle) - 5 * cos(2*angle) - 2 * cos(3*angle) - cos(4*angle)) * size.y * 0.3 / 32
		inner_points.push_back(center + Vector2(x, y - size.y*0.1))
	draw_colored_polygon(inner_points, Color(0.7, 0.1, 0.1))

func draw_bow_mouth(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(-size.x/2, 0),
		center + Vector2(-size.x/4, -size.y/2),
		center + Vector2(0, 0),
		center + Vector2(size.x/4, -size.y/2),
		center + Vector2(size.x/2, 0),
		center + Vector2(0, size.y/2)
	])
	draw_colored_polygon(points, color)
	
	# Inner lips
	draw_line(center + Vector2(-size.x/3, -size.y/6), center + Vector2(size.x/3, -size.y/6), Color(0.7, 0.1, 0.1), 2)

func draw_straight_mouth(center, size, color):
	draw_rect(Rect2(center.x - size.x/2, center.y - size.y/4, size.x, size.y/2), color)
	draw_line(center + Vector2(-size.x/2, 0), center + Vector2(size.x/2, 0), Color(0.7, 0.1, 0.1), 2)

func draw_round_mouth(center, size, color):
	draw_circle(center, size.x/3, color)
	draw_circle(center, size.x/4, Color(0.7, 0.1, 0.1))

func draw_downturned_mouth(center, size, color):
	var points = PackedVector2Array()
	for i in range(16):
		var t = float(i) / 15.0
		var x = lerp(-size.x/2, size.x/2, t)
		var y = size.y/3 * sin(t * PI)
		points.push_back(center + Vector2(x, y))
	draw_polyline(points, color, 3)
	
	# Inner lips
	var inner_points = PackedVector2Array()
	for i in range(16):
		var t = float(i) / 15.0
		var x = lerp(-size.x/3, size.x/3, t)
		var y = size.y/5 * sin(t * PI) - 2
		inner_points.push_back(center + Vector2(x, y))
	draw_polyline(inner_points, Color(0.7, 0.1, 0.1), 2)

# Chin shapes
func draw_round_chin(center, size, color):
	draw_circle(center, size.x/2, color)

func draw_square_chin(center, size, color):
	draw_rect(Rect2(center.x - size.x/2, center.y - size.y/2, size.x, size.y), color)

func draw_pointed_chin(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(-size.x/2, -size.y/2),
		center + Vector2(size.x/2, -size.y/2),
		center + Vector2(0, size.y/2)
	])
	draw_colored_polygon(points, color)

func draw_cleft_chin(center, size, color):
	draw_circle(center + Vector2(-size.x/4, 0), size.x/3, color)
	draw_circle(center + Vector2(size.x/4, 0), size.x/3, color)
	draw_line(center + Vector2(0, -size.y/3), center + Vector2(0, size.y/3), color.darkened(0.2), 2)

func draw_dimpled_chin(center, size, color):
	draw_circle(center, size.x/2, color)
	draw_circle(center + Vector2(-size.x/5, size.y/5), size.x/10, color.darkened(0.2))
	draw_circle(center + Vector2(size.x/5, size.y/5), size.x/10, color.darkened(0.2))

func draw_receding_chin(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(-size.x/2, -size.y/2),
		center + Vector2(size.x/2, -size.y/2),
		center + Vector2(size.x/3, size.y/2),
		center + Vector2(-size.x/3, size.y/2)
	])
	draw_colored_polygon(points, color)

func draw_protruding_chin(center, size, color):
	var points = PackedVector2Array([
		center + Vector2(-size.x/2, -size.y/2),
		center + Vector2(size.x/2, -size.y/2),
		center + Vector2(size.x/1.5, size.y/2),
		center + Vector2(-size.x/1.5, size.y/2)
	])
	draw_colored_polygon(points, color)

func draw_double_chin(center, size, color):
	draw_circle(center, size.x/2, color)
	draw_arc(center + Vector2(0, size.y/2), size.x/1.5, 0, PI, 16, color)

# Neck shapes
func draw_short_neck(center, size, color):
	draw_rect(Rect2(center.x - size.x/2, center.y - size.y/3, size.x, size.y/1.5), color)

func draw_long_neck(center, size, color):
	draw_rect(Rect2(center.x - size.x/2, center.y - size.y/2, size.x, size.y*1.2), color)

func draw_thick_neck(center, size, color):
	draw_rect(Rect2(center.x - size.x/1.5, center.y - size.y/2, size.x*1.3, size.y), color)

func draw_thin_neck(center, size, color):
	draw_rect(Rect2(center.x - size.x/3, center.y - size.y/2, size.x/1.5, size.y), color)

func draw_average_neck(center, size, color):
	draw_rect(Rect2(center.x - size.x/2, center.y - size.y/2, size.x, size.y), color)

func draw_muscular_neck(center, size, color):
	draw_rect(Rect2(center.x - size.x/1.8, center.y - size.y/2, size.x*1.1, size.y), color)
	draw_line(center + Vector2(-size.x/4, -size.y/3), center + Vector2(-size.x/4, size.y/2), color.darkened(0.1), 3)
	draw_line(center + Vector2(size.x/4, -size.y/3), center + Vector2(size.x/4, size.y/2), color.darkened(0.1), 3)

func draw_slender_neck(center, size, color):
	draw_rect(Rect2(center.x - size.x/3, center.y - size.y/2, size.x/1.5, size.y*1.1), color)

func draw_broad_neck(center, size, color):
	draw_rect(Rect2(center.x - size.x/1.3, center.y - size.y/2, size.x*1.5, size.y), color)
