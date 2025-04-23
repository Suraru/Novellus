extends Control

# Base path for character assets
const BASE_PATH = "res://assets/character/"

# Character data
var current_character = {}
var current_race = "human"
var character_parts = {}
var available_parts = {}

# Default scales
var DEFAULT_BELLY_SCALE = Vector2(0.33, 0.33)
var DEFAULT_PART_SCALE = Vector2(1.0, 1.0)

# Track opened panels
var open_panels = {}

# Original positions of head parts
var original_positions = {}

func _ready():
	# Initialize everything
	setup_ui_connections()
	check_edit_mode()
	load_character_data()
	store_original_part_positions()
	initialize_body_parts()
	update_character_preview()

func setup_ui_connections():
	# Connect main buttons
	$ButtonPanel/BackButton.pressed.connect(_on_back_button_pressed)
	$ButtonPanel/RandomizeButton.pressed.connect(_on_randomize_button_pressed)
	$ButtonPanel/ConfirmButton.pressed.connect(_on_confirm_button_pressed)
	
	# Connect all section buttons in both tabs
	connect_all_section_buttons()
	
	# Connect edit separately checkboxes for paired parts
	connect_all_edit_separately_options()
	
	# Connect sliders for all body parts
	connect_all_sliders()
	
	# Setup color tab
	setup_colors_tab()

func connect_all_section_buttons():
	# Head tab sections
	var head_sections = ["Hair", "Head", "Eyes", "Ears", "Nose", "Mouth", "Chin", "Neck"]
	for section in head_sections:
		setup_collapsible_section("Head", section)
	
	# Body tab sections
	var body_sections = ["Torso", "Belly", "Arms", "Hands", "Legs", "Feet", "Back", "Tail"]
	for section in body_sections:
		setup_collapsible_section("Body", section)

func connect_all_edit_separately_options():
	var paired_parts = ["Eyes", "Ears", "Arms", "Hands", "Legs", "Feet"]
	for part in paired_parts:
		connect_edit_separately(part)

func connect_all_sliders():
	var all_parts = ["Head", "Eyes", "Ears", "Nose", "Mouth", "Chin", "Neck", 
					"Torso", "Belly", "Arms", "Hands", "Legs", "Feet", "Back", "Tail"]
	for part in all_parts:
		connect_sliders_for_part(part)

func setup_collapsible_section(tab_name, section_name):
	# Fix for the Neck section - there was a naming mismatch in the scene
	var button_name = section_name + "Button"
	if section_name == "Neck":
		button_name = "ChinButton" # The scene had "ChinButton" for the Neck section
	
	var button_path = "ScrollContainer/SelectionMargin/TabContainer/" + tab_name + "/" + tab_name + "PartsPanel/" + section_name + "Section/" + button_name
	var options_path = "ScrollContainer/SelectionMargin/TabContainer/" + tab_name + "/" + tab_name + "PartsPanel/" + section_name + "Section/" + section_name + "Options"
	
	if has_node(button_path) and has_node(options_path):
		get_node(button_path).pressed.connect(func(): toggle_panel(tab_name, section_name))
		open_panels[section_name] = false

func toggle_panel(tab_name, section_name):
	var options_path = "ScrollContainer/SelectionMargin/TabContainer/" + tab_name + "/" + tab_name + "PartsPanel/" + section_name + "Section/" + section_name + "Options"
	
	if has_node(options_path):
		var options_node = get_node(options_path)
		open_panels[section_name] = !open_panels[section_name]
		options_node.visible = open_panels[section_name]
		
		if open_panels[section_name]:
			populate_style_options(section_name.to_lower())

func store_original_part_positions():
	# Store the original positions of all head parts
	original_positions = {
		"eyes_l": $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeL.position,
		"eyes_r": $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeR.position,
		"ears_l": $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarL.position,
		"ears_r": $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarR.position,
		"nose": $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/Nose.position,
		"mouth": $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/Mouth.position,
		"chin": $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/Chin.position
	}
	
	# Store as part of character_parts for persistence
	character_parts["original_positions"] = original_positions.duplicate()

func connect_edit_separately(part_name):
	var tab_name = "Head" if part_name in ["Eyes", "Ears"] else "Body"
	var checkbox_path = "ScrollContainer/SelectionMargin/TabContainer/" + tab_name + "/" + tab_name + "PartsPanel/" + part_name + "Section/" + part_name + "Options/EditSeparatelyBox"
	var combined_path = "ScrollContainer/SelectionMargin/TabContainer/" + tab_name + "/" + tab_name + "PartsPanel/" + part_name + "Section/" + part_name + "Options/" + part_name + "CombinedContainer"
	var separate_path = "ScrollContainer/SelectionMargin/TabContainer/" + tab_name + "/" + tab_name + "PartsPanel/" + part_name + "Section/" + part_name + "Options/" + part_name + "SeparateContainer"
	
	# Check for style containers
	var style_container_path = "ScrollContainer/SelectionMargin/TabContainer/" + tab_name + "/" + tab_name + "PartsPanel/" + part_name + "Section/" + part_name + "Options/" + part_name + "StyleContainer"
	var style_separated_path = "ScrollContainer/SelectionMargin/TabContainer/" + tab_name + "/" + tab_name + "PartsPanel/" + part_name + "Section/" + part_name + "Options/" + part_name + "StyleSeperatedContainer"
	
	if has_node(checkbox_path) and has_node(combined_path) and has_node(separate_path):
		var checkbox = get_node(checkbox_path)
		
		# Connect toggle function for main containers
		checkbox.toggled.connect(func(button_pressed): 
			get_node(combined_path).visible = !button_pressed
			get_node(separate_path).visible = button_pressed
			
			# Also toggle style containers if they exist
			if has_node(style_container_path) and has_node(style_separated_path):
				get_node(style_container_path).visible = !button_pressed
				get_node(style_separated_path).visible = button_pressed
				
			update_character_preview()
		)

func connect_sliders_for_part(part_name):
	var tab_name = "Head" if part_name in ["Head", "Eyes", "Ears", "Nose", "Mouth", "Chin", "Neck", "Hair"] else "Body"
	var base_path = "ScrollContainer/SelectionMargin/TabContainer/" + tab_name + "/" + tab_name + "PartsPanel/" + part_name + "Section/" + part_name + "Options"
	
	# Connect width slider
	var width_path = base_path + "/" + part_name + "Sliders/" + part_name + "WidthContainer/" + part_name + "WidthSlider"
	if has_node(width_path):
		get_node(width_path).value_changed.connect(func(value): update_part_dimension(part_name.to_lower(), "width", value))
	
	# Connect height slider
	var height_path = base_path + "/" + part_name + "Sliders/" + part_name + "HeightContainer/" + part_name + "HeightSlider"
	if has_node(height_path):
		get_node(height_path).value_changed.connect(func(value): update_part_dimension(part_name.to_lower(), "height", value))
	
	# Connect position slider
	var pos_path = base_path + "/" + part_name + "Sliders/" + part_name + "PositionContainer/" + part_name + "PositionSlider"
	if has_node(pos_path):
		get_node(pos_path).value_changed.connect(func(value): update_part_dimension(part_name.to_lower(), "position", value))
	
	# Connect special sliders for specific parts
	match part_name:
		"Eyes":
			# Eyes spacing slider
			var spacing_path = base_path + "/EyesSpacingContainer/EyesSpacingSlider"
			if has_node(spacing_path):
				get_node(spacing_path).value_changed.connect(func(value): update_part_dimension("eyes", "spacing", value))
		"Arms", "Hands", "Legs", "Feet":
			# Size slider for limbs
			var size_path = base_path + "/" + part_name + "CombinedContainer/" + part_name + "SizeContainer/" + part_name + "SizeSlider"
			if has_node(size_path):
				get_node(size_path).value_changed.connect(func(value): update_part_dimension(part_name.to_lower(), "size", value))

func update_part_dimension(part_name, dimension, value):
	# For belly scale, use a range of 0.1 to 0.5
	var belly_min_scale = 0.1
	var belly_max_scale = 0.5
	var belly_scale = belly_min_scale + (value / 100.0) * (belly_max_scale - belly_min_scale)
	
	# For other parts, use a range around 1.0
	var min_multiplier = 0.5
	var max_multiplier = 1.5
	var scale_multiplier = min_multiplier + (value / 100.0) * (max_multiplier - min_multiplier)
	
	# Get the nodes to modify
	var part_node = null
	var paired_node = null
	
	match part_name:
		"head":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head
		"eyes":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeL
			paired_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeR
			
			# Special case for eye spacing
			if dimension == "spacing":
				if original_positions.has("eyes_l") and original_positions.has("eyes_r"):
					var spacing_factor = value / 100.0
					var max_offset = 20
					
					part_node.position.x = original_positions["eyes_l"].x - (spacing_factor * max_offset)
					paired_node.position.x = original_positions["eyes_r"].x + (spacing_factor * max_offset)
				return
		"ears":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarL
			paired_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarR
		"nose":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/Nose
		"mouth":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/Mouth
		"chin":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/Chin
		"neck":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck
		"torso":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso
		"belly":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly
			
			# Special handling for belly
			if dimension in ["width", "size"]:
				part_node.scale.x = belly_scale
			if dimension in ["height", "size"]:
				part_node.scale.y = belly_scale
				
			# Store in character data
			character_parts[part_name][dimension] = value / 100.0
			return
		"arms":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/ArmL
			paired_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/ArmR
		"hands":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/ArmL/HandL
			paired_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/ArmR/HandR
		"legs":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/LegL
			paired_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/LegR
		"feet":
			part_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/LegL/FeetL
			paired_node = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/LegR/FeetR
	
	if part_node:
		match dimension:
			"width":
				part_node.scale.x = DEFAULT_PART_SCALE.x * scale_multiplier
				if paired_node:
					paired_node.scale.x = DEFAULT_PART_SCALE.x * scale_multiplier
			"height":
				part_node.scale.y = DEFAULT_PART_SCALE.y * scale_multiplier
				if paired_node:
					paired_node.scale.y = DEFAULT_PART_SCALE.y * scale_multiplier
			"size":
				part_node.scale = DEFAULT_PART_SCALE * scale_multiplier
				if paired_node:
					paired_node.scale = DEFAULT_PART_SCALE * scale_multiplier
			"position":
				# Position adjustments for facial features
				if part_name in ["eyes", "ears", "nose", "mouth", "chin"]:
					var part_key = part_name
					var paired_key = part_name
					
					# Handle special cases for paired parts
					if part_name == "eyes":
						part_key = "eyes_l"
						paired_key = "eyes_r"
					elif part_name == "ears":
						part_key = "ears_l"
						paired_key = "ears_r"
					
					if original_positions.has(part_key):
						var original_pos = original_positions[part_key]
						
						# Map 0-100 to position offsets (-15 to 15 pixels)
						var position_factor = (value / 100.0) * 2.0 - 1.0  # -1 to 1
						var max_offset = 15
						
						part_node.position.y = original_pos.y + (position_factor * max_offset)
						
						if paired_node and original_positions.has(paired_key):
							var paired_original = original_positions[paired_key]
							paired_node.position.y = paired_original.y + (position_factor * max_offset)
		
		# Store the adjusted value in character_parts
		if !character_parts.has(part_name):
			character_parts[part_name] = {}
			
		character_parts[part_name][dimension] = value / 100.0

func setup_colors_tab():
	# Connect color pickers for hair, skin, eyes, and details
	var color_sections = ["Hair", "Skin", "Eye", "Detail"]
	for section in color_sections:
		connect_color_pickers(section)
	
	# Setup eye color separation toggle
	if has_node("ScrollContainer/SelectionMargin/TabContainer/Colors/ColorsPanel/EyeColorSection/EditSeparatelyBox"):
		var checkbox = $"ScrollContainer/SelectionMargin/TabContainer/Colors/ColorsPanel/EyeColorSection/EditSeparatelyBox"
		var combined_grid = $"ScrollContainer/SelectionMargin/TabContainer/Colors/ColorsPanel/EyeColorSection/EyesColorCombinedGrid"
		var separate_container = $"ScrollContainer/SelectionMargin/TabContainer/Colors/ColorsPanel/EyeColorSection/EyesColorSeparateContainer"
		
		checkbox.toggled.connect(func(button_pressed):
			combined_grid.visible = !button_pressed
			separate_container.visible = button_pressed
		)

func connect_color_pickers(color_type):
	var grid_path = "ScrollContainer/SelectionMargin/TabContainer/Colors/ColorsPanel/" + color_type + "ColorSection/" + color_type + "ColorGrid"
	
	if has_node(grid_path):
		var grid = get_node(grid_path)
		for child in grid.get_children():
			if child is ColorPickerButton:
				child.color_changed.connect(func(color): apply_color(color_type.to_lower(), color))

func apply_color(color_type, color):
	# Check if we need to create a shader
	var shader = load("res://shaders/color_overlay.gdshader")
	
	if shader == null:
		# Create a default shader if it doesn't exist
		shader = Shader.new()
		shader.code = """
		shader_type canvas_item;
		
		uniform vec4 overlay_color : source_color;
		uniform float blend_factor = 0.5;
		
		void fragment() {
			vec4 texture_color = texture(TEXTURE, UV);
			
			// Keep alpha from original texture
			float alpha = texture_color.a;
			
			// Mix the texture color with overlay color based on luminance
			float luminance = 0.299 * texture_color.r + 0.587 * texture_color.g + 0.114 * texture_color.b;
			vec3 blended_color = mix(texture_color.rgb, overlay_color.rgb, blend_factor * (1.0 - luminance));
			
			COLOR = vec4(blended_color, alpha);
		}
		"""
	
	# Create the shader material
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("overlay_color", color)
	
	# Apply to appropriate parts based on color type
	match color_type:
		"hair":
			# Apply to hair
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/HairFront.material = shader_material
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/HairBack.material = shader_material
			
			# Store in character data
			character_parts["hair"]["color"] = color
		"skin":
			# Apply to all body parts that should have skin color
			var skin_parts = [
				$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly,
				$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso,
				$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck,
				$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/LegL,
				$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/LegR,
				$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/ArmL,
				$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/ArmR
			]
			
			for part in skin_parts:
				part.material = shader_material
			
			# Store in character data
			character_parts["skin_color"] = color
		"eye":
			# Apply to eyes
			var eye_left = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeL
			var eye_right = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeR
			
			# Check if separate eye colors are enabled
			var separate_checkbox = $"ScrollContainer/SelectionMargin/TabContainer/Colors/ColorsPanel/EyeColorSection/EditSeparatelyBox"
			
			if separate_checkbox and separate_checkbox.button_pressed:
				# This would be implemented for separate eye colors
				# For now, use the same color for both
				eye_left.material = shader_material
				eye_right.material = shader_material
			else:
				eye_left.material = shader_material
				eye_right.material = shader_material
			
			# Store in character data
			character_parts["eyes"]["color"] = color
		"detail":
			# Apply to detail parts (using ears as example)
			var detail_material = ShaderMaterial.new()
			detail_material.shader = shader
			detail_material.set_shader_parameter("overlay_color", color)
			detail_material.set_shader_parameter("blend_factor", 0.3)  # Less intense for details
			
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarL.material = detail_material
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarR.material = detail_material
			
			# Store in character data
			character_parts["detail_color"] = color

func check_edit_mode():
	# Check if we're in character edit mode
	if GlobalVars.edit_character_mode:
		$ButtonPanel/BackButton.disabled = true

func load_character_data():
	# Load the selected character or create a new one
	if GlobalVars.selected_character_id.is_empty():
		current_character = create_default_character()
	else:
		# Try to load from file
		var character_path = GlobalVars.CHARACTERS_DIR + GlobalVars.selected_character_id + ".json"
		if FileAccess.file_exists(character_path):
			var file = FileAccess.open(character_path, FileAccess.READ)
			var json_text = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var error = json.parse(json_text)
			if error == OK:
				current_character = json.data
			else:
				current_character = create_default_character()
		else:
			current_character = create_default_character()
	
	# Get race and appearance data
	if current_character.has("race"):
		current_race = current_character["race"].to_lower()
	
	if current_character.has("appearance"):
		character_parts = current_character["appearance"]
	else:
		character_parts = create_default_appearance()

func create_default_character():
	return {
		"id": str(Time.get_unix_time_from_system()),
		"name": "New Character",
		"race": "Human",
		"gender": "Masculine",
		"age": 25,
		"appearance": create_default_appearance()
	}

func create_default_appearance():
	return {
		"head": {"style": "normal", "width": 1.0, "height": 1.0},
		"hair": {"style": "short", "color": Color(0.5, 0.3, 0.1)},
		"eyes": {"style": "normal", "color": Color(0.2, 0.2, 0.6), "width": 1.0, "height": 1.0, "spacing": 0.5},
		"nose": {"style": "normal", "width": 1.0, "height": 1.0},
		"mouth": {"style": "normal", "width": 1.0, "height": 1.0},
		"ears": {"style": "normal", "width": 1.0, "height": 1.0},
		"chin": {"style": "normal", "width": 1.0, "height": 1.0},
		"neck": {"style": "normal", "width": 1.0, "height": 1.0},
		"torso": {"style": "normal", "width": 1.0, "height": 1.0},
		"belly": {"style": "normal", "width": 0.33, "height": 0.33},  # Note: using proper belly scale here
		"arms": {"style": "normal", "size": 1.0},
		"hands": {"style": "normal", "size": 1.0},
		"legs": {"style": "normal", "size": 1.0},
		"feet": {"style": "normal", "size": 1.0},
		"tail": {"style": "none", "width": 1.0, "height": 1.0},
		"skin_color": Color(0.9, 0.7, 0.6),
		"detail_color": Color(0.3, 0.3, 0.3)
	}

func initialize_body_parts():
	# Reset belly to default scale
	$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly.scale = DEFAULT_BELLY_SCALE
	
	# Scan for available parts
	scan_available_parts()
	
	# Apply styles and colors
	apply_body_part_styles()
	apply_colors()

func scan_available_parts():
	available_parts = {}
	var race_filter = current_race.to_lower()
	var part_types = ["head", "hair", "eyes", "nose", "mouth", "ears", "chin", "neck", 
					"torso", "belly", "arms", "hands", "legs", "feet", "back", "tail"]
	
	for part_type in part_types:
		available_parts[part_type] = []
		
		# Try to open the directory
		var part_dir = DirAccess.open(BASE_PATH + part_type)
		if part_dir:
			part_dir.list_dir_begin()
			var file_name = part_dir.get_next()
			
			# Scan all files
			while file_name != "":
				if file_name.ends_with(".png") and file_name.begins_with(part_type) and file_name.contains(race_filter):
					# Parse filename to get style info
					var parts = file_name.get_basename().split("-")
					if parts.size() >= 3:
						var style_name = parts[2]
						
						# Add to available parts
						var file_path = BASE_PATH + part_type + "/" + file_name
						var style_info = {
							"path": file_path,
							"style": style_name
						}
						
						# Add subtype if available
						if parts.size() >= 4:
							style_info["subtype"] = parts[3]
						
						available_parts[part_type].append(style_info)
				
				file_name = part_dir.get_next()
			
			part_dir.list_dir_end()
		
		# Add fallback if needed
		if available_parts[part_type].size() == 0:
			var fallback_path = BASE_PATH + part_type + "/" + part_type + "-human-normal.png"
			available_parts[part_type].append({
				"path": fallback_path,
				"style": "normal"
			})

func apply_body_part_styles():
	# Apply textures for all body parts
	var parts = ["head", "hair", "eyes", "nose", "mouth", "ears", "chin", "neck", 
				"torso", "belly", "arms", "hands", "legs", "feet"]
	
	for part in parts:
		apply_texture_for_part(part)
	
	# Special cases for optional parts
	if character_parts.has("tail") and character_parts["tail"]["style"] != "none":
		apply_texture_for_part("tail")
	
	if character_parts.has("back"):
		apply_texture_for_part("back")

func apply_texture_for_part(part_name):
	# Find the texture path
	var style = character_parts[part_name]["style"]
	var path = find_texture_path_for_style(part_name, style)
	
	if path:
		var texture = load(path)
		if texture:
			# Store current scales and positions
			var scales = {}
			var positions = {}
			
			# Get nodes and store their current state
			match part_name:
				"belly":
					scales["belly"] = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly.scale
				"eyes":
					var eye_l = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeL
					var eye_r = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeR
					scales["eye_l"] = eye_l.scale
					scales["eye_r"] = eye_r.scale
					positions["eye_l"] = eye_l.position
					positions["eye_r"] = eye_r.position
				"ears":
					var ear_l = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarL
					var ear_r = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarR
					scales["ear_l"] = ear_l.scale
					scales["ear_r"] = ear_r.scale
					positions["ear_l"] = ear_l.position
					positions["ear_r"] = ear_r.position
			
			# Apply the texture to the appropriate nodes
			apply_texture_to_node(part_name, texture)
			
			# Restore scales and positions
			match part_name:
				"belly":
					if scales.has("belly"):
						$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly.scale = scales["belly"]
				"eyes":
					if scales.has("eye_l"):
						$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeL.scale = scales["eye_l"]
					if scales.has("eye_r"):
						$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeR.scale = scales["eye_r"]
					if positions.has("eye_l"):
						$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeL.position = positions["eye_l"]
					if positions.has("eye_r"):
						$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeR.position = positions["eye_r"]
				"ears":
					if scales.has("ear_l"):
						$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarL.scale = scales["ear_l"]
					if scales.has("ear_r"):
						$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarR.scale = scales["ear_r"]
					if positions.has("ear_l"):
						$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarL.position = positions["ear_l"]
					if positions.has("ear_r"):
						$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarR.position = positions["ear_r"]

func find_texture_path_for_style(part_name, style_name):
	# Find texture with matching style
	if available_parts.has(part_name):
		for part_info in available_parts[part_name]:
			if part_info["style"] == style_name:
				return part_info["path"]
	
	# Fallback to first available
	if available_parts.has(part_name) and available_parts[part_name].size() > 0:
		return available_parts[part_name][0]["path"]
	
	return null

func apply_texture_to_node(part_name, texture):
	match part_name:
		"hair":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/HairFront.texture = texture
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/HairBack.texture = texture
		"eyes":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeL.texture = texture
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EyeR.texture = texture
		"nose":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/Nose.texture = texture
		"mouth":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/Mouth.texture = texture
		"ears":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarL.texture = texture
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/EarR.texture = texture
		"chin":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck/Head/Chin.texture = texture
		"neck":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/Neck.texture = texture
		"torso":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso.texture = texture
		"belly":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly.texture = texture
		"arms":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/ArmL.texture = texture
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/ArmR.texture = texture
		"hands":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/ArmL/HandL.texture = texture
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/Torso/ArmR/HandR.texture = texture
		"legs":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/LegL.texture = texture
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/LegR.texture = texture
		"feet":
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/LegL/FeetL.texture = texture
			$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly/LegR/FeetR.texture = texture
		"back", "tail":
			# Add implementation for back and tail if needed
			pass

func apply_colors():
	# Apply saved colors from character data
	if character_parts.has("hair") and character_parts["hair"].has("color"):
		apply_color("hair", character_parts["hair"]["color"])
	
	if character_parts.has("skin_color"):
		apply_color("skin", character_parts["skin_color"])
	
	if character_parts.has("eyes") and character_parts["eyes"].has("color"):
		apply_color("eye", character_parts["eyes"]["color"])
	
	if character_parts.has("detail_color"):
		apply_color("detail", character_parts["detail_color"])

func populate_style_options(part_name):
	# Find the appropriate grid container
	var grid_path = ""
	var tab_name = "Head" if part_name in ["head", "hair", "eyes", "ears", "nose", "mouth", "chin", "neck"] else "Body"
	
	# Determine the correct grid path based on part
	if part_name in ["head", "nose", "mouth", "chin", "neck", "torso", "belly", "back", "tail"]:
		grid_path = "ScrollContainer/SelectionMargin/TabContainer/" + tab_name + "/" + tab_name + "PartsPanel/" + part_name.capitalize() + "Section/" + part_name.capitalize() + "Options/" + part_name.capitalize() + "ShapeContainer/" + part_name.capitalize() + "ShapePreview"
	elif part_name == "hair":
		grid_path = "ScrollContainer/SelectionMargin/TabContainer/Head/HeadPartsPanel/HairSection/HairOptions/HairStyleContainer/HairStylePreview"
	elif part_name in ["eyes", "ears", "arms", "hands", "legs", "feet"]:
		grid_path = "ScrollContainer/SelectionMargin/TabContainer/" + tab_name + "/" + tab_name + "PartsPanel/" + part_name.capitalize() + "Section/" + part_name.capitalize() + "Options/" + part_name.capitalize() + "StyleContainer/" + part_name.capitalize() + "StylePreview"
	
	# Check if grid exists
	if has_node(grid_path):
		var grid = get_node(grid_path)
		
		# Clear existing buttons
		for child in grid.get_children():
			child.queue_free()
		
		# Create new texture buttons for available styles
		if available_parts.has(part_name) and available_parts[part_name].size() > 0:
			for part_info in available_parts[part_name]:
				var texture_button = TextureButton.new()
				texture_button.texture_normal = load(part_info["path"])
				texture_button.custom_minimum_size = Vector2(80, 80)
				texture_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
				texture_button.ignore_texture_size = true
				
				# Connect button press
				texture_button.pressed.connect(func(): select_part_style(part_name, part_info["style"]))
				
				# Add to grid
				grid.add_child(texture_button)

func select_part_style(part_name, style_name):
	# Update character part style
	if character_parts.has(part_name):
		character_parts[part_name]["style"] = style_name
	else:
		character_parts[part_name] = {"style": style_name}
	
	# Apply new texture
	apply_texture_for_part(part_name)
	
	# Update preview
	update_character_preview()

func update_character_preview():
	# Set belly scale first
	if character_parts["belly"].has("width") and character_parts["belly"].has("height"):
		var belly_min_scale = 0.1
		var belly_max_scale = 0.5
		var belly_width = belly_min_scale + character_parts["belly"]["width"] * (belly_max_scale - belly_min_scale)
		var belly_height = belly_min_scale + character_parts["belly"]["height"] * (belly_max_scale - belly_min_scale)
		
		$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly.scale = Vector2(belly_width, belly_height)
	else:
		$CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait/Belly.scale = DEFAULT_BELLY_SCALE
	
	# Adjust all other parts
	for part_name in character_parts:
		if part_name != "original_positions" and part_name != "skin_color" and part_name != "detail_color":
			# Apply dimensions for standard parts
			if part_name in ["head", "eyes", "ears", "nose", "mouth", "chin", "neck", "torso"]:
				if character_parts[part_name].has("width"):
					update_part_dimension(part_name, "width", character_parts[part_name]["width"] * 100)
				if character_parts[part_name].has("height"):
					update_part_dimension(part_name, "height", character_parts[part_name]["height"] * 100)
			
			# Apply size for limbs
			if part_name in ["arms", "hands", "legs", "feet"]:
				if character_parts[part_name].has("size"):
					update_part_dimension(part_name, "size", character_parts[part_name]["size"] * 100)
			
			# Apply special cases
			if part_name == "eyes" and character_parts[part_name].has("spacing"):
				update_part_dimension(part_name, "spacing", character_parts[part_name]["spacing"] * 100)
	
	# Update sprite preview
	update_sprite_preview()

func update_sprite_preview():
	# Create a simple sprite preview
	var portrait = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait
	var front_preview = $CharacterPreview/MarginContainer/VBoxContainer/SpritePreview/Front
	
	# In a real implementation, you would generate proper sprites here
	# For now, we'll just duplicate the portrait
	var viewport = SubViewport.new()
	viewport.size = Vector2(200, 200)
	viewport.transparent_bg = true
	
	var portrait_copy = portrait.duplicate()
	viewport.add_child(portrait_copy)
	
	await get_tree().process_frame
	
	front_preview.texture = viewport.get_texture()

func _on_randomize_button_pressed():
	# Randomize all parts
	for part_name in available_parts:
		if available_parts[part_name].size() > 0:
			var random_index = randi() % available_parts[part_name].size()
			select_part_style(part_name, available_parts[part_name][random_index]["style"])
	
	# Randomize colors
	randomize_colors()
	
	# Randomize dimensions within reasonable ranges
	randomize_dimensions()
	
	# Update preview
	update_character_preview()

func randomize_colors():
	# Get color grids
	var hair_colors = $"ScrollContainer/SelectionMargin/TabContainer/Colors/ColorsPanel/HairColorSection/HairColorGrid".get_children()
	var skin_colors = $"ScrollContainer/SelectionMargin/TabContainer/Colors/ColorsPanel/SkinColorSection/SkinColorGrid".get_children()
	var eye_colors = $"ScrollContainer/SelectionMargin/TabContainer/Colors/ColorsPanel/EyeColorSection/EyesColorCombinedGrid".get_children()
	var detail_colors = $"ScrollContainer/SelectionMargin/TabContainer/Colors/ColorsPanel/DetailColorSection/DetailColorGrid".get_children()
	
	# Randomize hair color
	if hair_colors.size() > 0:
		var random_color = hair_colors[randi() % hair_colors.size()].color
		character_parts["hair"]["color"] = random_color
		apply_color("hair", random_color)
	
	# Randomize skin color
	if skin_colors.size() > 0:
		var random_color = skin_colors[randi() % skin_colors.size()].color
		character_parts["skin_color"] = random_color
		apply_color("skin", random_color)
	
	# Randomize eye color
	if eye_colors.size() > 0:
		var random_color = eye_colors[randi() % eye_colors.size()].color
		character_parts["eyes"]["color"] = random_color
		apply_color("eye", random_color)
	
	# Randomize detail color
	if detail_colors.size() > 0:
		var random_color = detail_colors[randi() % detail_colors.size()].color
		character_parts["detail_color"] = random_color
		apply_color("detail", random_color)

func randomize_dimensions():
	# Randomize dimensions with reasonable values
	for part_name in character_parts:
		if part_name != "original_positions" and part_name != "skin_color" and part_name != "detail_color":
			if part_name == "belly":
				# Special case for belly
				character_parts[part_name]["width"] = 0.2 + randf() * 0.3  # 0.2 to 0.5
				character_parts[part_name]["height"] = 0.2 + randf() * 0.3  # 0.2 to 0.5
			elif part_name in ["head", "eyes", "ears", "nose", "mouth", "chin", "neck", "torso"]:
				character_parts[part_name]["width"] = 0.8 + randf() * 0.4  # 0.8 to 1.2
				character_parts[part_name]["height"] = 0.8 + randf() * 0.4  # 0.8 to 1.2
			elif part_name in ["arms", "hands", "legs", "feet"]:
				character_parts[part_name]["size"] = 0.8 + randf() * 0.4  # 0.8 to 1.2
			
			# Special case for eye spacing
			if part_name == "eyes":
				character_parts[part_name]["spacing"] = 0.3 + randf() * 0.4  # 0.3 to 0.7

func _on_confirm_button_pressed():
	# Save character data
	current_character["appearance"] = character_parts
	
	# Create directory if needed
	var dir = DirAccess.open("user://")
	if !dir.dir_exists(GlobalVars.CHARACTERS_DIR.trim_suffix("/")):
		dir.make_dir(GlobalVars.CHARACTERS_DIR.trim_suffix("/"))
	
	# Save to file
	var character_path = GlobalVars.CHARACTERS_DIR + current_character["id"] + ".json"
	var file = FileAccess.open(character_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(current_character, "  "))
	file.close()
	
	# Set selected character ID in GlobalVars
	GlobalVars.selected_character_id = current_character["id"]
	
	# Go to character build scene
	get_tree().change_scene_to_file("res://scenes/mainmenu/CharacterBuild.tscn")

func _on_back_button_pressed():
	# Go back to race selection
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/RaceSelection.tscn")
