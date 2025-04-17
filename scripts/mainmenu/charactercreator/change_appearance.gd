extends Control

@onready var background = $Characterbg

var character_data = {}
var character_preview = null
var body_parts = ["Hair", "Head", "Eyes", "Ears", "Nose", "Mouth", "Chin", "Neck", "Torso", "Arms", "Hands", "Belly", "Back", "Tail", "Legs", "Feet"]

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

# Default scale ranges for each body part
var scale_ranges = {
	"hair": Vector2(0.8, 1.2),
	"head": Vector2(0.8, 1.2),
	"eyes": Vector2(0.7, 1.3),
	"ears": Vector2(0.7, 1.3),
	"nose": Vector2(0.7, 1.3),
	"mouth": Vector2(0.7, 1.3),
	"chin": Vector2(0.8, 1.2),
	"neck": Vector2(0.8, 1.2),
	"torso": Vector2(0.8, 1.2),
	"arms": Vector2(0.8, 1.2),
	"hands": Vector2(0.7, 1.3),
	"belly": Vector2(0.8, 1.2),
	"back": Vector2(0.8, 1.2),
	"tail": Vector2(0.7, 1.3),
	"legs": Vector2(0.8, 1.2),
	"feet": Vector2(0.7, 1.3)
}

@onready var navigation_back_button = $ButtonPanel/BackButton
@onready var start_button = $ButtonPanel/StartButton

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	# Connect UI buttons
	start_button.pressed.connect(on_start_pressed)
	navigation_back_button.pressed.connect(_on_back_pressed)
	
	# Connect navigation buttons for each body part
	for part in body_parts:
		var part_lower = part.to_lower()
		
		# Connect back and forward buttons for part types
		var part_prev_button = get_node_or_null("SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer/" + part + "Container/" + part + "ButtonsContainer/" + part + "BackButton")
		var part_next_button = get_node_or_null("SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer/" + part + "Container/" + part + "ButtonsContainer/" + part + "ForwardButton")
		
		if part_prev_button:
			part_prev_button.pressed.connect(_on_part_back_pressed.bind(part_lower))
		else:
			print("Warning: Cannot find previous button for " + part)
			
		if part_next_button:
			part_next_button.pressed.connect(_on_part_forward_pressed.bind(part_lower))
		else:
			print("Warning: Cannot find next button for " + part)
		
		# Use the existing HSlider for the scale functionality
		var slider = get_node_or_null("SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer/" + part + "Container/MarginContainer/" + part + "HSlider")
		if slider:
			slider.value_changed.connect(_on_scale_slider_value_changed.bind(part_lower))
		else:
			print("Warning: Cannot find slider for " + part)
	
	# Load character data
	load_character_data()
	update_ui()
	
	# Create and add the character preview
	character_preview = preload("res://scripts/mainmenu/charactercreator/character_generation.gd").new()
	$PreviewMargin/PreviewContainer/SpriteContainer.add_child(character_preview)
	
	# Center the character preview in the container
	character_preview.position = Vector2(
		$PreviewMargin/PreviewContainer/SpriteContainer.size.x / 2,
		$PreviewMargin/PreviewContainer/SpriteContainer.size.y / 2
	)
	
	# Update the preview with current character data
	update_character_preview()

func _on_viewport_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Handle background scaling
	var bg_texture_size = background.texture.get_size()
	var bg_scale_x = viewport_size.x / bg_texture_size.x
	var bg_scale_y = viewport_size.y / bg_texture_size.y
	var scaling_factor = max(bg_scale_x, bg_scale_y)
	
	background.scale = Vector2(scaling_factor, scaling_factor)
	background.centered = false

func load_character_data():
	character_data = GlobalState.get_active_character_data()
	
	if character_data.is_empty():
		print("No active character found")
		# Initialize with default values
		character_data = {"appearance": {}}
		for part in body_parts:
			var part_lower = part.to_lower()
			character_data["appearance"][part_lower] = {
				"type": 0,
				"scale": 1.0
			}
	else:
		# Initialize missing body parts with default values
		for part in body_parts:
			var part_lower = part.to_lower()
			if not character_data.has("appearance"):
				character_data["appearance"] = {}
			
			if not character_data["appearance"].has(part_lower):
				character_data["appearance"][part_lower] = {
					"type": 0,
					"scale": 1.0
				}
			elif typeof(character_data["appearance"][part_lower]) == TYPE_INT:
				# Convert old format to new format
				var old_value = character_data["appearance"][part_lower]
				character_data["appearance"][part_lower] = {
					"type": old_value,
					"scale": 1.0
				}

func save_character_data():
	# Save to the active save file
	GlobalState.add_character_to_save(character_data)
	update_character_preview()

func update_ui():
	# Update all body part labels to show current values
	for part in body_parts:
		var part_lower = part.to_lower()
		var type_value = 0
		var scale_value = 1.0
		
		# Get current value from character data
		if character_data.has("appearance") and character_data["appearance"].has(part_lower):
			if typeof(character_data["appearance"][part_lower]) == TYPE_DICTIONARY:
				type_value = character_data["appearance"][part_lower]["type"]
				scale_value = character_data["appearance"][part_lower]["scale"]
			else:
				# Handle old format
				type_value = character_data["appearance"][part_lower]
		
		# Update the type label text
		var type_description = part_types[part][type_value] if type_value < part_types[part].size() else part_types[part][0]
		
		var display_label = get_node_or_null("SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer/" + part + "Container/" + part + "ButtonsContainer/" + part + "Display")
		if display_label:
			display_label.text = type_description
		
		# Update slider - now used for scale
		var slider = get_node_or_null("SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer/" + part + "Container/MarginContainer/" + part + "HSlider")
		if slider:
			var min_scale = scale_ranges[part_lower].x
			var max_scale = scale_ranges[part_lower].y
			var normalized_scale = (scale_value - min_scale) / (max_scale - min_scale) * 100
			slider.value = normalized_scale
		
		# Update scale display if it exists
		var scale_display = get_node_or_null("SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer/" + part + "Container/" + part + "ButtonsContainer/" + part + "ScaleDisplay")
		if scale_display:
			scale_display.text = "Scale: %.2f" % scale_value
	
	# Update the character preview
	update_character_preview()

func _on_part_back_pressed(part_name):
	var current_value = character_data["appearance"][part_name]["type"]
	var part_upper = part_name.capitalize()
	
	# Decrement value (with wrap-around)
	current_value = (current_value - 1) % part_types[part_upper].size()
	if current_value < 0:
		current_value = part_types[part_upper].size() - 1
	
	character_data["appearance"][part_name]["type"] = current_value
	update_ui()

func _on_part_forward_pressed(part_name):
	var current_value = character_data["appearance"][part_name]["type"]
	var part_upper = part_name.capitalize()
	
	# Increment value (with wrap-around)
	current_value = (current_value + 1) % part_types[part_upper].size()
	
	character_data["appearance"][part_name]["type"] = current_value
	update_ui()

func _on_scale_slider_value_changed(value, part_name):
	# Convert slider value (0-100) to scale value within range
	var min_scale = scale_ranges[part_name].x
	var max_scale = scale_ranges[part_name].y
	var scale_value = min_scale + (value / 100.0) * (max_scale - min_scale)
	
	# Round to 2 decimal places for cleaner values
	scale_value = round(scale_value * 100) / 100.0
	
	character_data["appearance"][part_name]["scale"] = scale_value
	update_ui()

func on_start_pressed():
	save_character_data()
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/CharacterBuild.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/RaceSelection.tscn")

# Add a scale display label for a part if it doesn't exist
func add_scale_display_to_part(part):
	var part_buttons_path = "SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer/" + part + "Container/" + part + "ButtonsContainer"
	var buttons_container = get_node_or_null(part_buttons_path)
	if buttons_container:
		# Check if the display already exists
		var existing_display = buttons_container.get_node_or_null(part + "ScaleDisplay")
		if not existing_display:
			# Create new label
			var new_label = Label.new()
			new_label.name = part + "ScaleDisplay"
			new_label.text = "Scale: 1.00"
			new_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			buttons_container.add_child(new_label)
			return true
	return false

func update_character_preview():
	if character_preview:
		# Pass the character data to the preview
		character_preview.character_data = character_data
		# Force redraw
		character_preview.queue_redraw()

func _process(_delta):
	if character_preview and $PreviewMargin/PreviewContainer/SpriteContainer.size.x > 0:
		# Center the character preview in the container
		character_preview.position = Vector2(
			$PreviewMargin/PreviewContainer/SpriteContainer.size.x / 2,
			$PreviewMargin/PreviewContainer/SpriteContainer.size.y / 2
		)
		# Disable _process after initial positioning
		set_process(false)
