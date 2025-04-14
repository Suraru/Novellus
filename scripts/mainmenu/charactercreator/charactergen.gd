extends Node2D

# References to UI elements
var preview_container
var body_part_containers = {}
var active_parts = {}
var colors = {
	"hair": Color("#8B4513"),  # Default brown
	"skin": Color("#FFD7BA"),  # Default light skin
	"eyes": Color("#2E5090"),  # Default blue
	"detail": Color("#505050") # Default gray
}

# Part types and their variants
var part_types = {
	"Hair": ["Short", "Medium", "Long", "Curly", "Spiky", "Straight", "Bald", "Mohawk", "Ponytail", "Bun"],
	"Head": ["Round", "Square", "Oval", "Heart", "Long", "Diamond", "Triangle", "Rectangle"],
	"Eyes": ["Round", "Almond", "Narrow", "Wide", "Downturned", "Upturned", "Hooded", "Deep-set"],
	"Ears": ["Round", "Pointed", "Small", "Large", "Flat", "Protruding", "Attached", "Free"],
	"Nose": ["Straight", "Roman", "Button", "Aquiline", "Snub", "Greek", "Nubian", "Hawk"],
	"Mouth": ["Full", "Thin", "Wide", "Heart", "Bow", "Straight", "Round", "Downturned"],
	"Chin": ["Round", "Square", "Pointed", "Cleft", "Dimpled", "Receding", "Protruding", "Double"],
	"Neck": ["Short", "Long", "Thick", "Thin", "Average", "Muscular", "Slender", "Broad"],
	"Torso": ["Slim", "Muscular", "Broad", "Average", "Stocky", "Athletic", "Thin", "Plump"],
	"Arms": ["Thin", "Muscular", "Average", "Long", "Short", "Toned", "Slender", "Bulky"],
	"Hands": ["Small", "Large", "Slender", "Thick", "Average", "Bony", "Soft", "Calloused"],
	"Belly": ["Flat", "Round", "Toned", "Muscular", "Soft", "Average", "Thin", "Plump"],
	"Back": ["Straight", "Broad", "Narrow", "Muscular", "Average", "Hunched", "Arched", "Defined"],
	"Tail": ["None", "Short", "Long", "Bushy", "Thin", "Curled", "Straight", "Tufted"],
	"Legs": ["Short", "Long", "Muscular", "Thin", "Average", "Toned", "Slender", "Stocky"],
	"Feet": ["Small", "Large", "Average", "Narrow", "Wide", "Arched", "Flat", "Pointed"]
}

func _ready():
	# Get references to UI elements
	preview_container = get_node("../PreviewMargin/PreviewContainer/SpriteContainer")
	
	# Initialize active parts with default values
	for part in part_types.keys():
		active_parts[part] = {
			"type": 0,  # Index of the type in the array
			"slider": 50  # Default slider value (0-100)
		}
	
	# Connect signals for all body part UI elements
	setup_connections()
	
	# Initial drawing
	call_deferred("update_character")

func setup_connections():
	var body_part_container = get_node("../SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer")
	
	for part in part_types.keys():
		var container = body_part_container.get_node(part + "Container")
		if container:
			body_part_containers[part] = container
			
			# Connect buttons
			var back_button = container.get_node(part + "ButtonsContainer/" + part + "BackButton")
			var forward_button = container.get_node(part + "ButtonsContainer/" + part + "ForwardButton")
			var slider = container.get_node("MarginContainer/" + part + "HSlider")
			var display = container.get_node(part + "ButtonsContainer/" + part + "Display")
			
			# Update display initially
			display.text = part_types[part][active_parts[part]["type"]]
			
			# Connect signals
			back_button.connect("pressed", _on_back_button_pressed.bind(part))
			forward_button.connect("pressed", _on_forward_button_pressed.bind(part))
			slider.connect("value_changed", _on_slider_value_changed.bind(part))

func _on_back_button_pressed(part):
	active_parts[part]["type"] = (active_parts[part]["type"] - 1) % part_types[part].size()
	if active_parts[part]["type"] < 0:
		active_parts[part]["type"] = part_types[part].size() - 1
	
	# Update display
	var display = body_part_containers[part].get_node(part + "ButtonsContainer/" + part + "Display")
	display.text = part_types[part][active_parts[part]["type"]]
	
	update_character()

func _on_forward_button_pressed(part):
	active_parts[part]["type"] = (active_parts[part]["type"] + 1) % part_types[part].size()
	
	# Update display
	var display = body_part_containers[part].get_node(part + "ButtonsContainer/" + part + "Display")
	display.text = part_types[part][active_parts[part]["type"]]
	
	update_character()

func _on_slider_value_changed(value, part):
	active_parts[part]["slider"] = value
	update_character()

func update_character():
	# Clear previous drawings
	queue_redraw()

func _draw():
	# Draw the character based on active parts
	var canvas_size = Vector2(200, 400)  # Adjust based on your UI
	var center_x = canvas_size.x / 2
	
	# Calculate scale factor based on head size
	var head_scale = lerp(0.7, 1.3, active_parts["Head"]["slider"] / 100.0)
	
	# Base position calculations
	var head_y = canvas_size.y * 0.2
	var head_radius = 50 * head_scale
	var neck_top = head_y + head_radius * 0.9
	var neck_height = 30 * lerp(0.7, 1.3, active_parts["Neck"]["slider"] / 100.0)
	var torso_top = neck_top + neck_height
	
	# Draw parts from back to front
	draw_back(center_x, torso_top)
	draw_torso(center_x, torso_top)
	draw_arms(center_x, torso_top)
	draw_hands(center_x, torso_top)
	draw_legs(center_x, torso_top)
	draw_feet(center_x, torso_top)
	draw_tail(center_x, torso_top)
	draw_neck(center_x, neck_top, neck_height)
	draw_head(center_x, head_y, head_radius)
	draw_ears(center_x, head_y, head_radius)
	draw_face(center_x, head_y, head_radius)
	draw_hair(center_x, head_y, head_radius)

func draw_head(x, y, radius):
	var head_type = active_parts["Head"]["type"]
	var head_value = active_parts["Head"]["slider"] / 100.0
	
	# Base head shape
	var color = colors["skin"]
	
	match head_type:
		0:  # Round
			draw_circle(Vector2(x, y), radius, color)
		1:  # Square
			var size = radius * 1.8
			var rect = Rect2(x - size/2, y - size/2, size, size)
			draw_rect(rect, color)
		2:  # Oval
			var oval_height = radius * 1.4
			var oval_width = radius * 1.6 * lerp(0.8, 1.2, head_value)
			draw_ellipse(Vector2(x, y), Vector2(oval_width, oval_height), color)
		3:  # Heart
			draw_heart_head(x, y, radius, color)
		4:  # Long
			var oval_height = radius * 1.8 * lerp(0.9, 1.3, head_value)
			var oval_width = radius * 1.3
			draw_ellipse(Vector2(x, y), Vector2(oval_width, oval_height), color)
		5:  # Diamond
			draw_diamond_head(x, y, radius, color)
		6:  # Triangle
			draw_triangle_head(x, y, radius, color)
		7:  # Rectangle
			var width = radius * 1.6
			var height = radius * 2.0 * lerp(0.8, 1.2, head_value)
			var rect = Rect2(x - width/2, y - height/2, width, height)
			draw_rect(rect, color)
		_:  # Default to round
			draw_circle(Vector2(x, y), radius, color)

func draw_ellipse(center, size, color):
	# Draw an approximated ellipse using points
	var points = []
	var segments = 32
	for i in range(segments + 1):
		var angle = 2 * PI * i / segments
		var point = Vector2(
			center.x + cos(angle) * size.x,
			center.y + sin(angle) * size.y
		)
		points.append(point)
	draw_colored_polygon(points, color)

func draw_heart_head(x, y, radius, color):
	var points = []
	var segments = 32
	for i in range(segments + 1):
		var angle = 2 * PI * i / segments
		var point
		if angle < PI:
			# Bottom part (pointed)
			point = Vector2(
				x + cos(angle) * radius * 1.2,
				y + sin(angle) * radius * 1.5 + radius * 0.2
			)
		else:
			# Top part (two circles)
			if angle < 3 * PI / 2:
				point = Vector2(
					x - radius * 0.6 + cos(angle) * radius * 0.8,
					y - radius * 0.3 + sin(angle) * radius * 0.8
				)
			else:
				point = Vector2(
					x + radius * 0.6 + cos(angle) * radius * 0.8,
					y - radius * 0.3 + sin(angle) * radius * 0.8
				)
		points.append(point)
	draw_colored_polygon(points, color)

func draw_diamond_head(x, y, radius, color):
	var width = radius * 1.6
	var height = radius * 2.0
	var points = [
		Vector2(x, y - height/2),  # Top
		Vector2(x + width/2, y),   # Right
		Vector2(x, y + height/2),  # Bottom
		Vector2(x - width/2, y)    # Left
	]
	draw_colored_polygon(points, color)

func draw_triangle_head(x, y, radius, color):
	var height = radius * 2.0
	var width = radius * 1.8
	var points = [
		Vector2(x, y - height/2),         # Top
		Vector2(x + width/2, y + height/2), # Bottom right
		Vector2(x - width/2, y + height/2)  # Bottom left
	]
	draw_colored_polygon(points, color)

func draw_ears(x, y, head_radius):
	var ear_type = active_parts["Ears"]["type"]
	var ear_value = active_parts["Ears"]["slider"] / 100.0
	var color = colors["skin"]
	
	var ear_size = head_radius * 0.4 * lerp(0.7, 1.3, ear_value)
	var ear_position = 0.0  # -1.0 to 1.0, where 0 is middle of head height
	
	match ear_type:
		0:  # Round
			draw_circle(Vector2(x - head_radius - ear_size/3, y - head_radius * ear_position), ear_size, color)
			draw_circle(Vector2(x + head_radius + ear_size/3, y - head_radius * ear_position), ear_size, color)
		1:  # Pointed
			draw_triangle_ear(x - head_radius, y - head_radius * ear_position, ear_size, true, color)
			draw_triangle_ear(x + head_radius, y - head_radius * ear_position, ear_size, false, color)
		2:  # Small
			draw_circle(Vector2(x - head_radius, y - head_radius * ear_position), ear_size * 0.6, color)
			draw_circle(Vector2(x + head_radius, y - head_radius * ear_position), ear_size * 0.6, color)
		3:  # Large
			draw_circle(Vector2(x - head_radius - ear_size/2, y - head_radius * ear_position), ear_size * 1.3, color)
			draw_circle(Vector2(x + head_radius + ear_size/2, y - head_radius * ear_position), ear_size * 1.3, color)
		4:  # Flat
			var ear_width = ear_size * 0.6
			var ear_height = ear_size * 1.5
			draw_rect(Rect2(x - head_radius - ear_width, y - head_radius * ear_position - ear_height/2, ear_width, ear_height), color)
			draw_rect(Rect2(x + head_radius, y - head_radius * ear_position - ear_height/2, ear_width, ear_height), color)
		5:  # Protruding
			var ear_points_left = [
				Vector2(x - head_radius, y - head_radius * ear_position - ear_size),
				Vector2(x - head_radius - ear_size * 1.5, y - head_radius * ear_position),
				Vector2(x - head_radius, y - head_radius * ear_position + ear_size)
			]
			var ear_points_right = [
				Vector2(x + head_radius, y - head_radius * ear_position - ear_size),
				Vector2(x + head_radius + ear_size * 1.5, y - head_radius * ear_position),
				Vector2(x + head_radius, y - head_radius * ear_position + ear_size)
			]
			draw_colored_polygon(ear_points_left, color)
			draw_colored_polygon(ear_points_right, color)
		6:  # Attached
			draw_circle(Vector2(x - head_radius + ear_size/3, y - head_radius * ear_position), ear_size, color)
			draw_circle(Vector2(x + head_radius - ear_size/3, y - head_radius * ear_position), ear_size, color)
		7:  # Free
			draw_circle(Vector2(x - head_radius - ear_size, y - head_radius * ear_position), ear_size, color)
			draw_circle(Vector2(x + head_radius + ear_size, y - head_radius * ear_position), ear_size, color)
		_:  # Default to round
			draw_circle(Vector2(x - head_radius, y - head_radius * ear_position), ear_size, color)
			draw_circle(Vector2(x + head_radius, y - head_radius * ear_position), ear_size, color)

func draw_triangle_ear(x, y, size, is_left, color):
	var direction = -1.0 if is_left else 1.0
	var points = [
		Vector2(x, y - size),
		Vector2(x + direction * size * 1.5, y),
		Vector2(x, y + size)
	]
	draw_colored_polygon(points, color)

func draw_face(x, y, head_radius):
	draw_eyes(x, y, head_radius)
	draw_nose(x, y, head_radius)
	draw_mouth(x, y, head_radius)
	draw_chin(x, y, head_radius)

func draw_eyes(x, y, head_radius):
	var eye_type = active_parts["Eyes"]["type"]
	var eye_value = active_parts["Eyes"]["slider"] / 100.0
	var eye_spacing = head_radius * 0.5 * lerp(0.7, 1.3, eye_value)
	var eye_y = y - head_radius * 0.1
	var eye_size = head_radius * 0.15
	var pupil_size = eye_size * 0.5
	var eye_color = colors["eyes"]
	
	match eye_type:
		0:  # Round
			draw_circle(Vector2(x - eye_spacing, eye_y), eye_size, Color.WHITE)
			draw_circle(Vector2(x + eye_spacing, eye_y), eye_size, Color.WHITE)
			draw_circle(Vector2(x - eye_spacing, eye_y), pupil_size, eye_color)
			draw_circle(Vector2(x + eye_spacing, eye_y), pupil_size, eye_color)
		1:  # Almond
			draw_eye_almond(x - eye_spacing, eye_y, eye_size, Color.WHITE, eye_color, pupil_size)
			draw_eye_almond(x + eye_spacing, eye_y, eye_size, Color.WHITE, eye_color, pupil_size)
		2:  # Narrow
			draw_eye_almond(x - eye_spacing, eye_y, Vector2(eye_size * 1.3, eye_size * 0.6), Color.WHITE, eye_color, pupil_size * 0.8)
			draw_eye_almond(x + eye_spacing, eye_y, Vector2(eye_size * 1.3, eye_size * 0.6), Color.WHITE, eye_color, pupil_size * 0.8)
		3:  # Wide
			draw_circle(Vector2(x - eye_spacing, eye_y), eye_size * 1.2, Color.WHITE)
			draw_circle(Vector2(x + eye_spacing, eye_y), eye_size * 1.2, Color.WHITE)
			draw_circle(Vector2(x - eye_spacing, eye_y), pupil_size * 1.2, eye_color)
			draw_circle(Vector2(x + eye_spacing, eye_y), pupil_size * 1.2, eye_color)
		4:  # Downturned
			draw_eye_angled(x - eye_spacing, eye_y, eye_size, -0.2, Color.WHITE, eye_color, pupil_size)
			draw_eye_angled(x + eye_spacing, eye_y, eye_size, -0.2, Color.WHITE, eye_color, pupil_size)
		5:  # Upturned
			draw_eye_angled(x - eye_spacing, eye_y, eye_size, 0.2, Color.WHITE, eye_color, pupil_size)
			draw_eye_angled(x + eye_spacing, eye_y, eye_size, 0.2, Color.WHITE, eye_color, pupil_size)
		6:  # Hooded
			draw_eye_hooded(x - eye_spacing, eye_y, eye_size, Color.WHITE, eye_color, pupil_size)
			draw_eye_hooded(x + eye_spacing, eye_y, eye_size, Color.WHITE, eye_color, pupil_size)
		7:  # Deep-set
			draw_eye_deep_set(x - eye_spacing, eye_y, eye_size, Color.WHITE, eye_color, pupil_size)
			draw_eye_deep_set(x + eye_spacing, eye_y, eye_size, Color.WHITE, eye_color, pupil_size)
		_:  # Default to round
			draw_circle(Vector2(x - eye_spacing, eye_y), eye_size, Color.WHITE)
			draw_circle(Vector2(x + eye_spacing, eye_y), eye_size, Color.WHITE)
			draw_circle(Vector2(x - eye_spacing, eye_y), pupil_size, eye_color)
			draw_circle(Vector2(x + eye_spacing, eye_y), pupil_size, eye_color)

func draw_eye_almond(x, y, size, white_color, iris_color, pupil_size):
	if typeof(size) == TYPE_VECTOR2:
		var points = []
		var segments = 32
		for i in range(segments + 1):
			var angle = 2 * PI * i / segments
			var point = Vector2(
				x + cos(angle) * size.x,
				y + sin(angle) * size.y
			)
			points.append(point)
		draw_colored_polygon(points, white_color)
	else:
		var size_vec = Vector2(size * 1.5, size * 0.8)
		var points = []
		var segments = 32
		for i in range(segments + 1):
			var angle = 2 * PI * i / segments
			var point = Vector2(
				x + cos(angle) * size_vec.x,
				y + sin(angle) * size_vec.y
			)
			points.append(point)
		draw_colored_polygon(points, white_color)
	
	draw_circle(Vector2(x, y), pupil_size, iris_color)

func draw_eye_angled(x, y, size, angle, white_color, iris_color, pupil_size):
	var points = []
	var segments = 32
	var size_vec = Vector2(size * 1.5, size * 0.8)
	for i in range(segments + 1):
		var segment_angle = 2 * PI * i / segments
		var point_x = x + cos(segment_angle) * size_vec.x
		var point_y = y + sin(segment_angle) * size_vec.y + (point_x - x) * angle
		points.append(Vector2(point_x, point_y))
	draw_colored_polygon(points, white_color)
	
	draw_circle(Vector2(x, y), pupil_size, iris_color)

func draw_eye_hooded(x, y, size, white_color, iris_color, pupil_size):
	# Base eye
	draw_eye_almond(x, y, size, white_color, iris_color, pupil_size)
	
	# Hood part
	var hood_points = [
		Vector2(x - size * 1.5, y - size * 0.6),
		Vector2(x + size * 1.5, y - size * 0.6),
		Vector2(x + size * 1.5, y - size),
		Vector2(x - size * 1.5, y - size)
	]
	draw_colored_polygon(hood_points, colors["skin"])

func draw_eye_deep_set(x, y, size, white_color, iris_color, pupil_size):
	# Shadow around eye
	draw_circle(Vector2(x, y), size * 1.5, Color(0.7, 0.7, 0.7, 0.3))
	
	# Eye itself
	draw_circle(Vector2(x, y), size, white_color)
	draw_circle(Vector2(x, y), pupil_size, iris_color)

func draw_nose(x, y, head_radius):
	var nose_type = active_parts["Nose"]["type"]
	var nose_value = active_parts["Nose"]["slider"] / 100.0
	var nose_y = y + head_radius * 0.2
	var nose_size = head_radius * 0.2 * lerp(0.7, 1.3, nose_value)
	var color = colors["skin"].darkened(0.1)  # Slightly darker than skin
	
	match nose_type:
		0:  # Straight
			draw_line(Vector2(x, y), Vector2(x, nose_y), color, 2.0)
			draw_circle(Vector2(x, nose_y), nose_size * 0.5, color)
		1:  # Roman
			var points = [
				Vector2(x, y - nose_size * 0.5),
				Vector2(x + nose_size, y + nose_size * 0.5),
				Vector2(x, nose_y)
			]
			draw_colored_polygon(points, color)
		2:  # Button
			draw_circle(Vector2(x, nose_y - nose_size * 0.3), nose_size * 0.7, color)
		3:  # Aquiline
			var points = [
				Vector2(x, y - nose_size * 0.5),
				Vector2(x - nose_size * 0.2, y + nose_size * 0.3),
				Vector2(x, nose_y)
			]
			draw_colored_polygon(points, color)
		4:  # Snub
			draw_rect(Rect2(x - nose_size * 0.5, nose_y - nose_size, nose_size, nose_size), color)
		5:  # Greek
			draw_line(Vector2(x, y - nose_size * 0.5), Vector2(x, nose_y), color, 3.0)
		6:  # Nubian
			draw_triangle_nose(x, nose_y, nose_size, color)
		7:  # Hawk
			var points = [
				Vector2(x, y - nose_size * 0.5),
				Vector2(x + nose_size * 0.3, y + nose_size * 0.3),
				Vector2(x - nose_size * 0.3, y + nose_size * 0.3),
			]
			draw_colored_polygon(points, color)
		_:  # Default to straight
			draw_line(Vector2(x, y), Vector2(x, nose_y), color, 2.0)
			draw_circle(Vector2(x, nose_y), nose_size * 0.5, color)

func draw_triangle_nose(x, y, size, color):
	var points = [
		Vector2(x, y - size),
		Vector2(x + size, y + size * 0.5),
		Vector2(x - size, y + size * 0.5)
	]
	draw_colored_polygon(points, color)

func draw_mouth(x, y, head_radius):
	var mouth_type = active_parts["Mouth"]["type"]
	var mouth_value = active_parts["Mouth"]["slider"] / 100.0
	var mouth_y = y + head_radius * 0.5
	var mouth_width = head_radius * 0.7 * lerp(0.7, 1.3, mouth_value)
	var mouth_height = head_radius * 0.15
	var color = Color(0.9, 0.3, 0.3, 0.8)  # Reddish
	
	match mouth_type:
		0:  # Full
			draw_rect(Rect2(x - mouth_width/2, mouth_y - mouth_height/2, mouth_width, mouth_height), color)
		1:  # Thin
			draw_line(Vector2(x - mouth_width/2, mouth_y), Vector2(x + mouth_width/2, mouth_y), color, 2.0)
		2:  # Wide
			draw_rect(Rect2(x - mouth_width * 0.8, mouth_y - mouth_height * 0.3, mouth_width * 1.6, mouth_height * 0.6), color)
		3:  # Heart
			draw_heart_mouth(x, mouth_y, mouth_width, mouth_height, color)
		4:  # Bow
			draw_bow_mouth(x, mouth_y, mouth_width, mouth_height, color)
		5:  # Straight
			draw_line(Vector2(x - mouth_width/2, mouth_y), Vector2(x + mouth_width/2, mouth_y), color, 3.0)
		6:  # Round
			draw_circle(Vector2(x, mouth_y), mouth_width * 0.3, color)
		7:  # Downturned
			var points = [
				Vector2(x - mouth_width/2, mouth_y),
				Vector2(x, mouth_y + mouth_height),
				Vector2(x + mouth_width/2, mouth_y)
			]
			draw_colored_polygon(points, color)
		_:  # Default to full
			draw_rect(Rect2(x - mouth_width/2, mouth_y - mouth_height/2, mouth_width, mouth_height), color)

func draw_heart_mouth(x, y, width, height, color):
	var points = []
	var segments = 32
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = PI * t
		
		if t < 0.5:
			# Left curve
			var point = Vector2(
				x - width * 0.25 + cos(angle) * width * 0.25,
				y - height * 0.5 + sin(angle) * height
			)
			points.append(point)
		else:
			# Right curve
			var point = Vector2(
				x + width * 0.25 + cos(angle) * width * 0.25,
				y - height * 0.5 + sin(angle) * height
			)
			points.append(point)
	
	draw_colored_polygon(points, color)

func draw_bow_mouth(x, y, width, height, color):
	var points = [
		Vector2(x - width/2, y - height/2),
		Vector2(x, y),
		Vector2(x + width/2, y - height/2)
	]
	draw_polyline(points, color, 2.0)

func draw_chin(x, y, head_radius):
	var chin_type = active_parts["Chin"]["type"]
	var chin_value = active_parts["Chin"]["slider"] / 100.0
	var chin_y = y + head_radius * 0.7
	var chin_width = head_radius * 0.5 * lerp(0.7, 1.3, chin_value)
	var chin_height = head_radius * 0.2
	var color = colors["skin"]
	
	match chin_type:
		0:  # Round
			# Already part of the head
			pass
		1:  # Square
			var points = [
				Vector2(x - chin_width, chin_y - chin_height),
				Vector2(x + chin_width, chin_y - chin_height),
				Vector2(x + chin_width, chin_y),
				Vector2(x - chin_width, chin_y)
			]
			draw_colored_polygon(points, color)
		2:  # Pointed
			var points = [
				Vector2(x - chin_width, chin_y - chin_height),
				Vector2(x + chin_width, chin_y - chin_height),
				Vector2(x, chin_y + chin_height)
			]
			draw_colored_polygon(points, color)
		3:  # Cleft
			draw_circle(Vector2(x, chin_y), chin_width * 0.8, color)
			draw_line(Vector2(x, chin_y - chin_height * 0.5), Vector2(x, chin_y + chin_height * 0.5), color.darkened(0.2), 2.0)
		4:  # Dimpled
			draw_circle(Vector2(x, chin_y), chin_width * 0.8, color)
			draw_circle(Vector2(x, chin_y), chin_width * 0.2, color.darkened(0.2))
		5:  # Receding
			var points = [
				Vector2(x - chin_width, chin_y - chin_height),
				Vector2(x + chin_width, chin_y - chin_height),
				Vector2(x + chin_width * 0.7, chin_y),
				Vector2(x - chin_width * 0.7, chin_y)
			]
			draw_colored_polygon(points, color)
		6:  # Protruding
			var points = [
				Vector2(x - chin_width, chin_y - chin_height),
				Vector2(x + chin_width, chin_y - chin_height),
				Vector2(x + chin_width * 0.7, chin_y + chin_height),
				Vector2(x - chin_width * 0.7, chin_y + chin_height)
			]
			draw_colored_polygon(points, color)
		7:  # Double
			draw_circle(Vector2(x, chin_y), chin_width * 0.8, color)
			draw_circle(Vector2(x, chin_y + chin_height * 0.6), chin_width * 0.6, color)
		_:  # Default
			pass

func draw_neck(x, y, height):
	var neck_type = active_parts["Neck"]["type"]
	var neck_value = active_parts["Neck"]["slider"] / 100.0
	var neck_width = 30 * lerp(0.7, 1.3, neck_value)
	var color = colors["skin"]
	
	match neck_type:
		0:  # Short
			var neck_height = height * 0.7
			draw_rect(Rect2(x - neck_width/2, y, neck_width, neck_height), color)
		1:  # Long
			var neck_height = height * 1.3
			draw_rect(Rect2(x - neck_width/2, y, neck_width, neck_height), color)
		2:  # Thick
			var thick_width = neck_width * 1.5
			draw_rect(Rect2(x - thick_width/2, y, thick_width, height), color)
		3:  # Thin
			var thin_width = neck_width * 0.7
			draw_rect(Rect2(x - thin_width/2, y, thin_width, height), color)
		4:  # Average
			draw_rect(Rect2(x - neck_width/2, y, neck_width, height), color)
		5:  # Muscular
			var muscular_width = neck_width * 1.2
			draw_rect(Rect2(x - muscular_width/2, y, muscular_width, height), color)
			# Add muscle definition
			draw_line(Vector2(x - muscular_width/4, y), Vector2(x - muscular_width/4, y + height), color.darkened(0.1), 2.0)
			draw_line(Vector2(x + muscular_width/4, y), Vector2(x + muscular_width/4, y + height), color.darkened(0.1), 2.0)
		6:  # Slender
			var slender_width = neck_width * 0.8
			draw_rect(Rect2(x - slender_width/2, y, slender_width, height), color)
		7:  # Broad
			var broad_width = neck_width * 1.8
			draw_rect(Rect2(x - broad_width/2, y, broad_width, height), color)
		_:  # Default
			draw_rect(Rect2(x - neck_width/2, y, neck_width, height), color)

func draw_hair(x, y, head_radius):
	var hair_type = active_parts["Hair"]["type"]
	var hair_value = active_parts["Hair"]["slider"] / 100.0
	var hair_size = head_radius * lerp(0.9, 1.4, hair_value)
	var color = colors["hair"]
	
	match hair_type:
		0:  # Short
			draw_short_hair(x, y, head_radius, hair_size, color)
		1:  # Medium
			draw_medium_hair(x, y, head_radius, hair_size, color)
		2:  # Long
			draw_long_hair(x, y, head_radius, hair_size, color)
		3:  # Curly
			draw_curly_hair(x, y, head_radius, hair_size, color)
		4:  # Spiky
			draw_spiky_hair(x, y, head_radius, hair_size, color)
		5:  # Straight
			draw_straight_hair(x, y, head_radius, hair_size, color)
		6:  # Bald
			# No hair
			pass
		7:  # Mohawk
			draw_mohawk_hair(x, y, head_radius, hair_size, color)
		8:  # Ponytail
			draw_ponytail_hair(x, y, head_radius, hair_size, color)
		9:  # Bun
			draw_bun_hair(x, y, head_radius, hair_size, color)
		_:  # Default to short
			draw_short_hair(x, y, head_radius, hair_size, color)

func draw_short_hair(x, y, head_radius, hair_size, color):
	# Hair cap that follows head shape
	var points = []
	var segments = 12
	
	for i in range(segments + 1):
		var angle = PI * i / segments
		var point = Vector2(
			x + cos(angle) * (head_radius * 1.05),
			y - head_radius + sin(angle) * (head_radius * 1.05)
		)
		points.append(point)
	
	for i in range(segments, -1, -1):
		var angle = PI * i / segments
		var point = Vector2(
			x + cos(angle) * (head_radius * 0.95),
			y - head_radius * 0.9 + sin(angle) * (head_radius * 0.95)
		)
		points.append(point)
	
	draw_colored_polygon(points, color)

func draw_medium_hair(x, y, head_radius, hair_size, color):
	# Top hair
	draw_short_hair(x, y, head_radius, hair_size, color)
	
	# Side hair extensions
	var points_left = [
		Vector2(x - head_radius * 1.05, y - head_radius * 0.5),
		Vector2(x - head_radius * 1.2, y),
		Vector2(x - head_radius * 1.3, y + head_radius * 0.5),
		Vector2(x - head_radius * 0.9, y + head_radius * 0.6),
		Vector2(x - head_radius * 0.8, y)
	]
	
	var points_right = [
		Vector2(x + head_radius * 1.05, y - head_radius * 0.5),
		Vector2(x + head_radius * 1.2, y),
		Vector2(x + head_radius * 1.3, y + head_radius * 0.5),
		Vector2(x + head_radius * 0.9, y + head_radius * 0.6),
		Vector2(x + head_radius * 0.8, y)
	]
	
	draw_colored_polygon(points_left, color)
	draw_colored_polygon(points_right, color)

func draw_long_hair(x, y, head_radius, hair_size, color):
	# Top hair
	draw_short_hair(x, y, head_radius, hair_size, color)
	
	# Long flowing hair
	var hair_width = head_radius * 1.3
	var hair_length = head_radius * 2.5
	
	var points = [
		Vector2(x - hair_width, y - head_radius * 0.3),
		Vector2(x - hair_width * 1.1, y + hair_length * 0.5),
		Vector2(x - hair_width * 0.9, y + hair_length),
		Vector2(x + hair_width * 0.9, y + hair_length),
		Vector2(x + hair_width * 1.1, y + hair_length * 0.5),
		Vector2(x + hair_width, y - head_radius * 0.3)
	]
	
	draw_colored_polygon(points, color)

func draw_curly_hair(x, y, head_radius, hair_size, color):
	# Base hair volume
	draw_circle(Vector2(x, y - head_radius * 0.2), head_radius * 1.3, color)
	
	# Add curls
	var curl_count = 12
	var curl_radius = head_radius * 0.3
	
	for i in range(curl_count):
		var angle = 2 * PI * i / curl_count
		var curl_x = x + cos(angle) * head_radius * 1.1
		var curl_y = y - head_radius * 0.2 + sin(angle) * head_radius * 1.1
		
		draw_circle(Vector2(curl_x, curl_y), curl_radius, color)

func draw_spiky_hair(x, y, head_radius, hair_size, color):
	# Base hair
	draw_circle(Vector2(x, y - head_radius * 0.3), head_radius * 0.9, color)
	
	# Add spikes
	var spike_count = 8
	var spike_length = head_radius * 0.8
	
	for i in range(spike_count):
		var angle = PI * i / (spike_count - 1)
		var base_x = x + cos(angle) * head_radius * 0.9
		var base_y = y - head_radius * 0.3 + sin(angle) * head_radius * 0.9
		var tip_x = x + cos(angle) * (head_radius * 0.9 + spike_length)
		var tip_y = y - head_radius * 0.3 + sin(angle) * (head_radius * 0.9 + spike_length)
		
		var points = [
			Vector2(base_x - cos(angle + PI/2) * head_radius * 0.2, base_y - sin(angle + PI/2) * head_radius * 0.2),
			Vector2(tip_x, tip_y),
			Vector2(base_x + cos(angle + PI/2) * head_radius * 0.2, base_y + sin(angle + PI/2) * head_radius * 0.2)
		]
		
		draw_colored_polygon(points, color)

func draw_straight_hair(x, y, head_radius, hair_size, color):
	# Top hair
	draw_short_hair(x, y, head_radius, hair_size, color)
	
	# Straight flowing hair
	var hair_width = head_radius * 1.2
	var hair_length = head_radius * 2.2
	
	var points = [
		Vector2(x - hair_width, y - head_radius * 0.3),
		Vector2(x - hair_width, y + hair_length),
		Vector2(x + hair_width, y + hair_length),
		Vector2(x + hair_width, y - head_radius * 0.3)
	]
	
	draw_colored_polygon(points, color)

func draw_mohawk_hair(x, y, head_radius, hair_size, color):
	var mohawk_width = head_radius * 0.3
	var mohawk_height = head_radius * 1.5
	
	var points = [
		Vector2(x - mohawk_width/2, y - head_radius),
		Vector2(x, y - head_radius - mohawk_height),
		Vector2(x + mohawk_width/2, y - head_radius)
	]
	
	draw_colored_polygon(points, color)

func draw_ponytail_hair(x, y, head_radius, hair_size, color):
	# Top hair
	draw_short_hair(x, y, head_radius, hair_size, color)
	
	# Ponytail
	var ponytail_width = head_radius * 0.7
	var ponytail_length = head_radius * 1.8
	
	var points = [
		Vector2(x - ponytail_width/2, y - head_radius * 0.6),
		Vector2(x + ponytail_width/2, y - head_radius * 0.6),
		Vector2(x + ponytail_width * 0.7, y + ponytail_length),
		Vector2(x - ponytail_width * 0.7, y + ponytail_length)
	]
	
	draw_colored_polygon(points, color)

func draw_bun_hair(x, y, head_radius, hair_size, color):
	# Top hair
	draw_short_hair(x, y, head_radius, hair_size, color)
	
	# Bun
	draw_circle(Vector2(x, y - head_radius * 1.2), head_radius * 0.6, color)

func draw_torso(x, y, start_y):
	var torso_type = active_parts["Torso"]["type"]
	var torso_value = active_parts["Torso"]["slider"] / 100.0
	var torso_width = 80 * lerp(0.7, 1.5, torso_value)
	var torso_height = 120 * lerp(0.8, 1.2, torso_value)
	var color = colors["skin"].lightened(0.1)
	
	match torso_type:
		0:  # Slim
			var slim_width = torso_width * 0.8
			var points = [
				Vector2(x - slim_width/2, start_y),
				Vector2(x + slim_width/2, start_y),
				Vector2(x + slim_width/2, start_y + torso_height),
				Vector2(x - slim_width/2, start_y + torso_height)
			]
			draw_colored_polygon(points, color)
		1:  # Muscular
			var muscular_width = torso_width * 1.2
			var points = [
				Vector2(x - muscular_width * 0.5, start_y),
				Vector2(x + muscular_width * 0.5, start_y),
				Vector2(x + muscular_width * 0.6, start_y + torso_height * 0.3),
				Vector2(x + muscular_width * 0.5, start_y + torso_height * 0.7),
				Vector2(x + muscular_width * 0.4, start_y + torso_height),
				Vector2(x - muscular_width * 0.4, start_y + torso_height),
				Vector2(x - muscular_width * 0.5, start_y + torso_height * 0.7),
				Vector2(x - muscular_width * 0.6, start_y + torso_height * 0.3)
			]
			draw_colored_polygon(points, color)
			
			# Muscle definition
			draw_line(Vector2(x, start_y + torso_height * 0.2), Vector2(x, start_y + torso_height * 0.8), color.darkened(0.1), 2.0)
			draw_line(Vector2(x - muscular_width * 0.25, start_y + torso_height * 0.3), Vector2(x - muscular_width * 0.25, start_y + torso_height * 0.6), color.darkened(0.1), 2.0)
			draw_line(Vector2(x + muscular_width * 0.25, start_y + torso_height * 0.3), Vector2(x + muscular_width * 0.25, start_y + torso_height * 0.6), color.darkened(0.1), 2.0)
		2:  # Broad
			var broad_width = torso_width * 1.4
			var points = [
				Vector2(x - broad_width/2, start_y),
				Vector2(x + broad_width/2, start_y),
				Vector2(x + torso_width/2, start_y + torso_height),
				Vector2(x - torso_width/2, start_y + torso_height)
			]
			draw_colored_polygon(points, color)
		3:  # Average
			var points = [
				Vector2(x - torso_width/2, start_y),
				Vector2(x + torso_width/2, start_y),
				Vector2(x + torso_width/2, start_y + torso_height),
				Vector2(x - torso_width/2, start_y + torso_height)
			]
			draw_colored_polygon(points, color)
		4:  # Stocky
			var stocky_width = torso_width * 1.3
			var points = [
				Vector2(x - stocky_width/2, start_y),
				Vector2(x + stocky_width/2, start_y),
				Vector2(x + stocky_width/2, start_y + torso_height),
				Vector2(x - stocky_width/2, start_y + torso_height)
			]
			draw_colored_polygon(points, color)
		5:  # Athletic
			var athletic_width = torso_width * 1.1
			var points = [
				Vector2(x - athletic_width * 0.5, start_y),
				Vector2(x + athletic_width * 0.5, start_y),
				Vector2(x + athletic_width * 0.55, start_y + torso_height * 0.3),
				Vector2(x + athletic_width * 0.45, start_y + torso_height * 0.7),
				Vector2(x + athletic_width * 0.4, start_y + torso_height),
				Vector2(x - athletic_width * 0.4, start_y + torso_height),
				Vector2(x - athletic_width * 0.45, start_y + torso_height * 0.7),
				Vector2(x - athletic_width * 0.55, start_y + torso_height * 0.3)
			]
			draw_colored_polygon(points, color)
		6:  # Thin
			var thin_width = torso_width * 0.7
			var points = [
				Vector2(x - thin_width/2, start_y),
				Vector2(x + thin_width/2, start_y),
				Vector2(x + thin_width/2, start_y + torso_height),
				Vector2(x - thin_width/2, start_y + torso_height)
			]
			draw_colored_polygon(points, color)
		7:  # Plump
			var plump_width = torso_width * 1.3
			var points = [
				Vector2(x - plump_width * 0.4, start_y),
				Vector2(x + plump_width * 0.4, start_y),
				Vector2(x + plump_width * 0.5, start_y + torso_height * 0.5),
				Vector2(x + plump_width * 0.45, start_y + torso_height),
				Vector2(x - plump_width * 0.45, start_y + torso_height),
				Vector2(x - plump_width * 0.5, start_y + torso_height * 0.5)
			]
			draw_colored_polygon(points, color)
		_:  # Default
			var points = [
				Vector2(x - torso_width/2, start_y),
				Vector2(x + torso_width/2, start_y),
				Vector2(x + torso_width/2, start_y + torso_height),
				Vector2(x - torso_width/2, start_y + torso_height)
			]
			draw_colored_polygon(points, color)

func draw_arms(x, y, start_y):
	var arm_type = active_parts["Arms"]["type"]
	var arm_value = active_parts["Arms"]["slider"] / 100.0
	var torso_width = 80 * lerp(0.7, 1.5, arm_value)
	var arm_width = 20 * lerp(0.7, 1.5, arm_value)
	var arm_length = 100 * lerp(0.8, 1.2, arm_value)
	var color = colors["skin"]
	
	match arm_type:
		0:  # Thin
			var thin_width = arm_width * 0.7
			draw_rect(Rect2(x - torso_width/2 - thin_width, start_y, thin_width, arm_length), color)
			draw_rect(Rect2(x + torso_width/2, start_y, thin_width, arm_length), color)
		1:  # Muscular
			var muscular_width = arm_width * 1.3
			
			# Left arm
			var left_points = [
				Vector2(x - torso_width/2 - muscular_width, start_y),
				Vector2(x - torso_width/2, start_y),
				Vector2(x - torso_width/2, start_y + arm_length),
				Vector2(x - torso_width/2 - muscular_width, start_y + arm_length)
			]
			draw_colored_polygon(left_points, color)
			
			# Muscle definition
			draw_line(Vector2(x - torso_width/2 - muscular_width/2, start_y + arm_length * 0.3), 
					  Vector2(x - torso_width/2 - muscular_width/2, start_y + arm_length * 0.7), 
					  color.darkened(0.1), 2.0)
			
			# Right arm
			var right_points = [
				Vector2(x + torso_width/2, start_y),
				Vector2(x + torso_width/2 + muscular_width, start_y),
				Vector2(x + torso_width/2 + muscular_width, start_y + arm_length),
				Vector2(x + torso_width/2, start_y + arm_length)
			]
			draw_colored_polygon(right_points, color)
			
			# Muscle definition
			draw_line(Vector2(x + torso_width/2 + muscular_width/2, start_y + arm_length * 0.3), 
					  Vector2(x + torso_width/2 + muscular_width/2, start_y + arm_length * 0.7), 
					  color.darkened(0.1), 2.0)
		2:  # Average
			draw_rect(Rect2(x - torso_width/2 - arm_width, start_y, arm_width, arm_length), color)
			draw_rect(Rect2(x + torso_width/2, start_y, arm_width, arm_length), color)
		3:  # Long
			var long_length = arm_length * 1.2
			draw_rect(Rect2(x - torso_width/2 - arm_width, start_y, arm_width, long_length), color)
			draw_rect(Rect2(x + torso_width/2, start_y, arm_width, long_length), color)
		4:  # Short
			var short_length = arm_length * 0.8
			draw_rect(Rect2(x - torso_width/2 - arm_width, start_y, arm_width, short_length), color)
			draw_rect(Rect2(x + torso_width/2, start_y, arm_width, short_length), color)
		5:  # Toned
			var toned_width = arm_width * 1.1
			
			# Left arm
			var left_points = [
				Vector2(x - torso_width/2 - toned_width, start_y),
				Vector2(x - torso_width/2, start_y),
				Vector2(x - torso_width/2, start_y + arm_length),
				Vector2(x - torso_width/2 - toned_width, start_y + arm_length)
			]
			draw_colored_polygon(left_points, color)
			
			# Right arm
			var right_points = [
				Vector2(x + torso_width/2, start_y),
				Vector2(x + torso_width/2 + toned_width, start_y),
				Vector2(x + torso_width/2 + toned_width, start_y + arm_length),
				Vector2(x + torso_width/2, start_y + arm_length)
			]
			draw_colored_polygon(right_points, color)
		6:  # Slender
			var slender_width = arm_width * 0.8
			draw_rect(Rect2(x - torso_width/2 - slender_width, start_y, slender_width, arm_length), color)
			draw_rect(Rect2(x + torso_width/2, start_y, slender_width, arm_length), color)
		7:  # Bulky
			var bulky_width = arm_width * 1.5
			draw_rect(Rect2(x - torso_width/2 - bulky_width, start_y, bulky_width, arm_length), color)
			draw_rect(Rect2(x + torso_width/2, start_y, bulky_width, arm_length), color)
		_:  # Default
			draw_rect(Rect2(x - torso_width/2 - arm_width, start_y, arm_width, arm_length), color)
			draw_rect(Rect2(x + torso_width/2, start_y, arm_width, arm_length), color)

func draw_hands(x, y, start_y):
	var hand_type = active_parts["Hands"]["type"]
	var hand_value = active_parts["Hands"]["slider"] / 100.0
	var torso_width = 80
	var arm_width = 20
	var arm_length = 100
	var hand_size = 15 * lerp(0.7, 1.5, hand_value)
	var color = colors["skin"]
	
	var hand_y = start_y + arm_length
	
	match hand_type:
		0:  # Small
			var small_size = hand_size * 0.8
			draw_circle(Vector2(x - torso_width/2 - arm_width/2, hand_y), small_size, color)
			draw_circle(Vector2(x + torso_width/2 + arm_width/2, hand_y), small_size, color)
		1:  # Large
			var large_size = hand_size * 1.3
			draw_circle(Vector2(x - torso_width/2 - arm_width/2, hand_y), large_size, color)
			draw_circle(Vector2(x + torso_width/2 + arm_width/2, hand_y), large_size, color)
		2:  # Slender
			var slender_width = hand_size * 0.6
			var slender_height = hand_size * 1.4
			
			draw_rect(Rect2(x - torso_width/2 - arm_width/2 - slender_width/2, hand_y - slender_height/2, slender_width, slender_height), color)
			draw_rect(Rect2(x + torso_width/2 + arm_width/2 - slender_width/2, hand_y - slender_height/2, slender_width, slender_height), color)
		3:  # Thick
			var thick_size = hand_size * 1.2
			draw_circle(Vector2(x - torso_width/2 - arm_width/2, hand_y), thick_size, color)
			draw_circle(Vector2(x + torso_width/2 + arm_width/2, hand_y), thick_size, color)
		4:  # Average
			draw_circle(Vector2(x - torso_width/2 - arm_width/2, hand_y), hand_size, color)
			draw_circle(Vector2(x + torso_width/2 + arm_width/2, hand_y), hand_size, color)
		5:  # Bony
			var bony_width = hand_size * 0.7
			var bony_height = hand_size * 1.2
			
			draw_rect(Rect2(x - torso_width/2 - arm_width/2 - bony_width/2, hand_y - bony_height/2, bony_width, bony_height), color)
			draw_rect(Rect2(x + torso_width/2 + arm_width/2 - bony_width/2, hand_y - bony_height/2, bony_width, bony_height), color)
			
# Finger lines
			for i in range(3):
				var line_y = hand_y - bony_height/2 + bony_height * (i + 1) / 4
				draw_line(Vector2(x - torso_width/2 - arm_width/2 - bony_width/2, line_y), 
						  Vector2(x - torso_width/2 - arm_width/2 + bony_width/2, line_y), 
						  color.darkened(0.1), 1.0)
				draw_line(Vector2(x + torso_width/2 + arm_width/2 - bony_width/2, line_y), 
						  Vector2(x + torso_width/2 + arm_width/2 + bony_width/2, line_y), 
						  color.darkened(0.1), 1.0)
		6:  # Soft
			var soft_size = hand_size * 1.1
			draw_circle(Vector2(x - torso_width/2 - arm_width/2, hand_y), soft_size, color)
			draw_circle(Vector2(x + torso_width/2 + arm_width/2, hand_y), soft_size, color)
		7:  # Calloused
			var calloused_size = hand_size * 1.1
			draw_circle(Vector2(x - torso_width/2 - arm_width/2, hand_y), calloused_size, color)
			draw_circle(Vector2(x + torso_width/2 + arm_width/2, hand_y), calloused_size, color)
			
			# Callous details
			draw_circle(Vector2(x - torso_width/2 - arm_width/2, hand_y), calloused_size * 0.6, color.darkened(0.1))
			draw_circle(Vector2(x + torso_width/2 + arm_width/2, hand_y), calloused_size * 0.6, color.darkened(0.1))
		_:  # Default
			draw_circle(Vector2(x - torso_width/2 - arm_width/2, hand_y), hand_size, color)
			draw_circle(Vector2(x + torso_width/2 + arm_width/2, hand_y), hand_size, color)

func draw_legs(x, y, start_y):
	var leg_type = active_parts["Legs"]["type"]
	var leg_value = active_parts["Legs"]["slider"] / 100.0
	var torso_width = 80
	var torso_height = 120
	var leg_width = 25 * lerp(0.7, 1.5, leg_value)
	var leg_length = 130 * lerp(0.8, 1.2, leg_value)
	var leg_spacing = 25
	var color = colors["skin"]
	
	var leg_y = start_y + torso_height
	
	match leg_type:
		0:  # Short
			var short_length = leg_length * 0.8
			draw_rect(Rect2(x - leg_spacing - leg_width, leg_y, leg_width, short_length), color)
			draw_rect(Rect2(x + leg_spacing, leg_y, leg_width, short_length), color)
		1:  # Long
			var long_length = leg_length * 1.2
			draw_rect(Rect2(x - leg_spacing - leg_width, leg_y, leg_width, long_length), color)
			draw_rect(Rect2(x + leg_spacing, leg_y, leg_width, long_length), color)
		2:  # Muscular
			var muscular_width = leg_width * 1.2
			
			# Left leg
			var left_points = [
				Vector2(x - leg_spacing - muscular_width, leg_y),
				Vector2(x - leg_spacing, leg_y),
				Vector2(x - leg_spacing, leg_y + leg_length),
				Vector2(x - leg_spacing - muscular_width, leg_y + leg_length)
			]
			draw_colored_polygon(left_points, color)
			
			# Muscle definition
			draw_line(Vector2(x - leg_spacing - muscular_width/2, leg_y + leg_length * 0.3), 
					  Vector2(x - leg_spacing - muscular_width/2, leg_y + leg_length * 0.7), 
					  color.darkened(0.1), 2.0)
			
			# Right leg
			var right_points = [
				Vector2(x + leg_spacing, leg_y),
				Vector2(x + leg_spacing + muscular_width, leg_y),
				Vector2(x + leg_spacing + muscular_width, leg_y + leg_length),
				Vector2(x + leg_spacing, leg_y + leg_length)
			]
			draw_colored_polygon(right_points, color)
			
			# Muscle definition
			draw_line(Vector2(x + leg_spacing + muscular_width/2, leg_y + leg_length * 0.3), 
					  Vector2(x + leg_spacing + muscular_width/2, leg_y + leg_length * 0.7), 
					  color.darkened(0.1), 2.0)
		3:  # Thin
			var thin_width = leg_width * 0.7
			draw_rect(Rect2(x - leg_spacing - thin_width, leg_y, thin_width, leg_length), color)
			draw_rect(Rect2(x + leg_spacing, leg_y, thin_width, leg_length), color)
		4:  # Average
			draw_rect(Rect2(x - leg_spacing - leg_width, leg_y, leg_width, leg_length), color)
			draw_rect(Rect2(x + leg_spacing, leg_y, leg_width, leg_length), color)
		5:  # Toned
			var toned_width = leg_width * 1.1
			
			# Left leg
			var left_points = [
				Vector2(x - leg_spacing - toned_width, leg_y),
				Vector2(x - leg_spacing, leg_y),
				Vector2(x - leg_spacing, leg_y + leg_length),
				Vector2(x - leg_spacing - toned_width, leg_y + leg_length)
			]
			draw_colored_polygon(left_points, color)
			
			# Right leg
			var right_points = [
				Vector2(x + leg_spacing, leg_y),
				Vector2(x + leg_spacing + toned_width, leg_y),
				Vector2(x + leg_spacing + toned_width, leg_y + leg_length),
				Vector2(x + leg_spacing, leg_y + leg_length)
			]
			draw_colored_polygon(right_points, color)
		6:  # Slender
			var slender_width = leg_width * 0.8
			draw_rect(Rect2(x - leg_spacing - slender_width, leg_y, slender_width, leg_length), color)
			draw_rect(Rect2(x + leg_spacing, leg_y, slender_width, leg_length), color)
		7:  # Stocky
			var stocky_width = leg_width * 1.3
			draw_rect(Rect2(x - leg_spacing - stocky_width, leg_y, stocky_width, leg_length), color)
			draw_rect(Rect2(x + leg_spacing, leg_y, stocky_width, leg_length), color)
		_:  # Default
			draw_rect(Rect2(x - leg_spacing - leg_width, leg_y, leg_width, leg_length), color)
			draw_rect(Rect2(x + leg_spacing, leg_y, leg_width, leg_length), color)

func draw_feet(x, y, start_y):
	var feet_type = active_parts["Feet"]["type"]
	var feet_value = active_parts["Feet"]["slider"] / 100.0
	var torso_height = 120
	var leg_length = 130
	var leg_spacing = 25
	var leg_width = 25
	var foot_width = 30 * lerp(0.7, 1.5, feet_value)
	var foot_height = 15 * lerp(0.7, 1.3, feet_value)
	var color = colors["skin"]
	
	var foot_y = start_y + torso_height + leg_length
	
	match feet_type:
		0:  # Small
			var small_width = foot_width * 0.8
			var small_height = foot_height * 0.8
			
			# Left foot
			var left_foot_x = x - leg_spacing - leg_width/2
			draw_rect(Rect2(left_foot_x - small_width/2, foot_y, small_width, small_height), color)
			
			# Right foot
			var right_foot_x = x + leg_spacing + leg_width/2
			draw_rect(Rect2(right_foot_x - small_width/2, foot_y, small_width, small_height), color)
		1:  # Large
			var large_width = foot_width * 1.3
			var large_height = foot_height * 1.2
			
			# Left foot
			var left_foot_x = x - leg_spacing - leg_width/2
			draw_rect(Rect2(left_foot_x - large_width/2, foot_y, large_width, large_height), color)
			
			# Right foot
			var right_foot_x = x + leg_spacing + leg_width/2
			draw_rect(Rect2(right_foot_x - large_width/2, foot_y, large_width, large_height), color)
		2:  # Average
			# Left foot
			var left_foot_x = x - leg_spacing - leg_width/2
			draw_rect(Rect2(left_foot_x - foot_width/2, foot_y, foot_width, foot_height), color)
			
			# Right foot
			var right_foot_x = x + leg_spacing + leg_width/2
			draw_rect(Rect2(right_foot_x - foot_width/2, foot_y, foot_width, foot_height), color)
		3:  # Narrow
			var narrow_width = foot_width * 0.7
			var narrow_height = foot_height * 1.1
			
			# Left foot
			var left_foot_x = x - leg_spacing - leg_width/2
			draw_rect(Rect2(left_foot_x - narrow_width/2, foot_y, narrow_width, narrow_height), color)
			
			# Right foot
			var right_foot_x = x + leg_spacing + leg_width/2
			draw_rect(Rect2(right_foot_x - narrow_width/2, foot_y, narrow_width, narrow_height), color)
		4:  # Wide
			var wide_width = foot_width * 1.4
			var wide_height = foot_height * 0.9
			
			# Left foot
			var left_foot_x = x - leg_spacing - leg_width/2
			draw_rect(Rect2(left_foot_x - wide_width/2, foot_y, wide_width, wide_height), color)
			
			# Right foot
			var right_foot_x = x + leg_spacing + leg_width/2
			draw_rect(Rect2(right_foot_x - wide_width/2, foot_y, wide_width, wide_height), color)
		5:  # Arched
			# Left foot
			var left_foot_x = x - leg_spacing - leg_width/2
			var left_points = [
				Vector2(left_foot_x - foot_width/2, foot_y),
				Vector2(left_foot_x + foot_width/2, foot_y),
				Vector2(left_foot_x + foot_width/2, foot_y + foot_height),
				Vector2(left_foot_x, foot_y + foot_height * 0.7),
				Vector2(left_foot_x - foot_width/2, foot_y + foot_height)
			]
			draw_colored_polygon(left_points, color)
			
			# Right foot
			var right_foot_x = x + leg_spacing + leg_width/2
			var right_points = [
				Vector2(right_foot_x - foot_width/2, foot_y),
				Vector2(right_foot_x + foot_width/2, foot_y),
				Vector2(right_foot_x + foot_width/2, foot_y + foot_height),
				Vector2(right_foot_x, foot_y + foot_height * 0.7),
				Vector2(right_foot_x - foot_width/2, foot_y + foot_height)
			]
			draw_colored_polygon(right_points, color)
		6:  # Flat
			var flat_width = foot_width * 1.1
			var flat_height = foot_height * 0.8
			
			# Left foot
			var left_foot_x = x - leg_spacing - leg_width/2
			draw_rect(Rect2(left_foot_x - flat_width/2, foot_y, flat_width, flat_height), color)
			
			# Right foot
			var right_foot_x = x + leg_spacing + leg_width/2
			draw_rect(Rect2(right_foot_x - flat_width/2, foot_y, flat_width, flat_height), color)
		7:  # Pointed
			# Left foot
			var left_foot_x = x - leg_spacing - leg_width/2
			var left_points = [
				Vector2(left_foot_x - foot_width/3, foot_y),
				Vector2(left_foot_x + foot_width/3, foot_y),
				Vector2(left_foot_x + foot_width/2, foot_y + foot_height),
				Vector2(left_foot_x - foot_width/2, foot_y + foot_height)
			]
			draw_colored_polygon(left_points, color)
			
			# Right foot
			var right_foot_x = x + leg_spacing + leg_width/2
			var right_points = [
				Vector2(right_foot_x - foot_width/3, foot_y),
				Vector2(right_foot_x + foot_width/3, foot_y),
				Vector2(right_foot_x + foot_width/2, foot_y + foot_height),
				Vector2(right_foot_x - foot_width/2, foot_y + foot_height)
			]
			draw_colored_polygon(right_points, color)
		_:  # Default
			# Left foot
			var left_foot_x = x - leg_spacing - leg_width/2
			draw_rect(Rect2(left_foot_x - foot_width/2, foot_y, foot_width, foot_height), color)
			
			# Right foot
			var right_foot_x = x + leg_spacing + leg_width/2
			draw_rect(Rect2(right_foot_x - foot_width/2, foot_y, foot_width, foot_height), color)

func draw_belly(x, y, start_y):
	var belly_type = active_parts["Belly"]["type"]
	var belly_value = active_parts["Belly"]["slider"] / 100.0
	var torso_width = 80
	var torso_height = 120
	var belly_width = torso_width * 0.8 * lerp(0.7, 1.3, belly_value)
	var belly_height = torso_height * 0.4 * lerp(0.7, 1.3, belly_value)
	var belly_y = start_y + torso_height * 0.6
	var color = colors["skin"]
	
	match belly_type:
		0:  # Flat
			# No specific drawing for flat belly
			pass
		1:  # Round
			draw_circle(Vector2(x, belly_y), belly_width/2, color.lightened(0.05))
		2:  # Toned
			draw_rect(Rect2(x - belly_width/2, belly_y - belly_height/2, belly_width, belly_height), color.lightened(0.03))
			
			# Muscle definition
			draw_line(Vector2(x, belly_y - belly_height/2), Vector2(x, belly_y + belly_height/2), color.darkened(0.1), 2.0)
			draw_line(Vector2(x - belly_width/4, belly_y), Vector2(x + belly_width/4, belly_y), color.darkened(0.1), 2.0)
		3:  # Muscular
			draw_rect(Rect2(x - belly_width/2, belly_y - belly_height/2, belly_width, belly_height), color.lightened(0.02))
			
			# Six-pack muscle definition
			for i in range(2):
				for j in range(3):
					var muscle_x = x - belly_width/4 + i * belly_width/2
					var muscle_y = belly_y - belly_height/3 + j * belly_height/3
					draw_circle(Vector2(muscle_x, muscle_y), belly_width/8, color.darkened(0.1))
		4:  # Soft
			draw_circle(Vector2(x, belly_y), belly_width/2 * 1.1, color.lightened(0.04))
		5:  # Average
			# No specific drawing for average belly
			pass
		6:  # Thin
			# No specific drawing for thin belly
			pass
		7:  # Plump
			draw_circle(Vector2(x, belly_y), belly_width/2 * 1.3, color.lightened(0.06))
		_:  # Default
			# No specific drawing for default belly
			pass

func draw_back(x, y, start_y):
	var back_type = active_parts["Back"]["type"]
	var back_value = active_parts["Back"]["slider"] / 100.0
	var torso_width = 80
	var torso_height = 120
	var back_width = torso_width * 0.8 * lerp(0.7, 1.3, back_value)
	var color = colors["skin"].darkened(0.05)  # Slightly darker than skin
	
	# This function adds details to the back which is behind the torso
	# So these are more subtle hints at the back shape
	
	match back_type:
		0:  # Straight
			# No specific drawing for straight back
			pass
		1:  # Broad
			# Draw shoulder lines
			draw_line(Vector2(x - back_width/2, start_y + torso_height * 0.1), 
					  Vector2(x - torso_width/2 - 10, start_y + torso_height * 0.1), 
					  color, 2.0)
			draw_line(Vector2(x + back_width/2, start_y + torso_height * 0.1), 
					  Vector2(x + torso_width/2 + 10, start_y + torso_height * 0.1), 
					  color, 2.0)
		2:  # Narrow
			# No specific drawing for narrow back
			pass
		3:  # Muscular
			# Draw back muscle definition
			draw_line(Vector2(x - back_width/4, start_y + torso_height * 0.2), 
					  Vector2(x - back_width/4, start_y + torso_height * 0.8), 
					  color, 2.0)
			draw_line(Vector2(x + back_width/4, start_y + torso_height * 0.2), 
					  Vector2(x + back_width/4, start_y + torso_height * 0.8), 
					  color, 2.0)
		4:  # Average
			# No specific drawing for average back
			pass
		5:  # Hunched
			# Draw hunched back curve
			var points = [
				Vector2(x - back_width/4, start_y + torso_height * 0.1),
				Vector2(x, start_y + torso_height * 0.3),
				Vector2(x - back_width/4, start_y + torso_height * 0.5)
			]
			draw_polyline(points, color, 2.0)
		6:  # Arched
			# Draw arched back curve
			var points = [
				Vector2(x, start_y + torso_height * 0.2),
				Vector2(x + back_width/4, start_y + torso_height * 0.5),
				Vector2(x, start_y + torso_height * 0.8)
			]
			draw_polyline(points, color, 2.0)
		7:  # Defined
			# Draw defined back muscle pattern
			for i in range(3):
				var y_pos = start_y + torso_height * (0.3 + i * 0.2)
				draw_line(Vector2(x - back_width/3, y_pos), 
						  Vector2(x + back_width/3, y_pos), 
						  color, 2.0)
		_:  # Default
			# No specific drawing for default back
			pass

func draw_tail(x, y, start_y):
	var tail_type = active_parts["Tail"]["type"]
	var tail_value = active_parts["Tail"]["slider"] / 100.0
	var torso_height = 120
	var tail_width = 20 * lerp(0.7, 1.3, tail_value)
	var tail_length = 100 * lerp(0.7, 1.5, tail_value)
	var tail_y = start_y + torso_height * 0.9
	var color = colors["skin"].darkened(0.1)  # Slightly darker than skin
	
	match tail_type:
		0:  # None
			# No tail to draw
			pass
		1:  # Short
			var short_length = tail_length * 0.5
			draw_tail_curve(x, tail_y, tail_width, short_length, 0.3, color)
		2:  # Long
			draw_tail_curve(x, tail_y, tail_width, tail_length, 0.5, color)
		3:  # Bushy
			draw_tail_curve(x, tail_y, tail_width * 1.5, tail_length * 0.8, 0.4, color)
			
			# Add fluff
			for i in range(5):
				var t = float(i) / 4.0
				var pos_x = x + cos(t * PI) * tail_length * 0.6
				var pos_y = tail_y + sin(t * PI) * tail_length * 0.5
				draw_circle(Vector2(pos_x, pos_y), tail_width * 0.8, color)
		4:  # Thin
			draw_tail_curve(x, tail_y, tail_width * 0.6, tail_length, 0.5, color)
		5:  # Curled
			draw_tail_spiral(x, tail_y, tail_width, tail_length * 0.7, color)
		6:  # Straight
			draw_line(Vector2(x, tail_y), Vector2(x, tail_y + tail_length), color, tail_width)
		7:  # Tufted
			draw_tail_curve(x, tail_y, tail_width, tail_length, 0.4, color)
			draw_circle(Vector2(x - tail_length * 0.4, tail_y + tail_length * 0.5), tail_width * 1.2, color)
		_:  # Default (None)
			pass

func draw_tail_curve(x, y, width, length, curve_factor, color):
	var points = []
	var segments = 16
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var pos_x = x - sin(t * PI) * length * curve_factor
		var pos_y = y + t * length
		points.append(Vector2(pos_x, pos_y))
	
	for i in range(segments):
		var start_point = points[i]
		var end_point = points[i + 1]
		draw_line(start_point, end_point, color, width * (1.0 - float(i) / segments * 0.5))

func draw_tail_spiral(x, y, width, length, color):
	var points = []
	var segments = 24
	var spirals = 1.5
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = t * PI * 2 * spirals
		var radius = length * (1.0 - t * 0.5)
		var pos_x = x + cos(angle) * radius
		var pos_y = y + sin(angle) * radius + t * length * 0.5
		points.append(Vector2(pos_x, pos_y))
	
	for i in range(segments):
		var start_point = points[i]
		var end_point = points[i + 1]
		draw_line(start_point, end_point, color, width * (1.0 - float(i) / segments * 0.5))

# Color adjustment functions
func _on_hair_color_changed(color):
	colors["hair"] = color
	update_character()

func _on_skin_color_changed(color):
	colors["skin"] = color
	update_character()

func _on_eyes_color_changed(color):
	colors["eyes"] = color
	update_character()

func _on_detail_color_changed(color):
	colors["detail"] = color
	update_character()

# Function to save character data
func save_character_data():
	var character_data = {
		"active_parts": active_parts,
		"colors": {
			"hair": colors["hair"].to_html(),
			"skin": colors["skin"].to_html(),
			"eyes": colors["eyes"].to_html(),
			"detail": colors["detail"].to_html()
		}
	}
	
	return character_data

# Function to load character data
func load_character_data(data):
	if data.has("active_parts"):
		active_parts = data["active_parts"]
	
	if data.has("colors"):
		if data["colors"].has("hair"):
			colors["hair"] = Color(data["colors"]["hair"])
		if data["colors"].has("skin"):
			colors["skin"] = Color(data["colors"]["skin"])
		if data["colors"].has("eyes"):
			colors["eyes"] = Color(data["colors"]["eyes"])
		if data["colors"].has("detail"):
			colors["detail"] = Color(data["colors"]["detail"])
	
	# Update UI
	for part in part_types.keys():
		if body_part_containers.has(part):
			var display = body_part_containers[part].get_node(part + "ButtonsContainer/" + part + "Display")
			var slider = body_part_containers[part].get_node("MarginContainer/" + part + "HSlider")
			
			display.text = part_types[part][active_parts[part]["type"]]
			slider.value = active_parts[part]["slider"]
	
	update_character()

# Function to randomize character
func randomize_character():
	for part in part_types.keys():
		active_parts[part]["type"] = randi() % part_types[part].size()
		active_parts[part]["slider"] = randi() % 100 + 1  # 1-100
	
	# Randomize colors
	colors["hair"] = Color(randf(), randf(), randf())
	colors["skin"] = Color(0.5 + randf() * 0.5, 0.3 + randf() * 0.7, 0.2 + randf() * 0.8)  # More natural skin tone range
	colors["eyes"] = Color(randf(), randf(), randf())
	colors["detail"] = Color(randf(), randf(), randf())
	
	# Update UI
	for part in part_types.keys():
		if body_part_containers.has(part):
			var display = body_part_containers[part].get_node(part + "ButtonsContainer/" + part + "Display")
			var slider = body_part_containers[part].get_node("MarginContainer/" + part + "HSlider")
			
			display.text = part_types[part][active_parts[part]["type"]]
			slider.value = active_parts[part]["slider"]
	
	update_character()

# Connect color picker signals
func connect_color_pickers():
	var color_picker_container = get_node("../SelectionMargin/ScrollContainer/TabContainer/ColorContainer")
	
	var hair_picker = color_picker_container.get_node("HairColorPicker")
	var skin_picker = color_picker_container.get_node("SkinColorPicker")
	var eyes_picker = color_picker_container.get_node("EyesColorPicker")
	var detail_picker = color_picker_container.get_node("DetailColorPicker")
	
	if hair_picker:
		hair_picker.color = colors["hair"]
		hair_picker.connect("color_changed", _on_hair_color_changed)
	
	if skin_picker:
		skin_picker.color = colors["skin"]
		skin_picker.connect("color_changed", _on_skin_color_changed)
	
	if eyes_picker:
		eyes_picker.color = colors["eyes"]
		eyes_picker.connect("color_changed", _on_eyes_color_changed)
	
	if detail_picker:
		detail_picker.color = colors["detail"]
		detail_picker.connect("color_changed", _on_detail_color_changed)

# Connect randomize button
func connect_randomize_button():
	var button = get_node("../SelectionMargin/ScrollContainer/TabContainer/ColorContainer/RandomizeButton")
	if button:
		button.connect("pressed", randomize_character)

# Export character as image
func export_character():
	var viewport = get_viewport()
	var img = viewport.get_texture().get_data()
	img.flip_y()  # Flip because Godot's Y axis is inverted
	
	var preview_rect = preview_container.get_global_rect()
	var cropped_img = Image.new()
	cropped_img.create(int(preview_rect.size.x), int(preview_rect.size.y), false, Image.FORMAT_RGBA8)
	cropped_img.blit_rect(img, Rect2(preview_rect.position, preview_rect.size), Vector2.ZERO)
	
	return cropped_img
