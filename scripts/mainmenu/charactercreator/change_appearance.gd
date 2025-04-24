extends Control

# Scene paths for navigation
const RACE_SELECTION_SCENE = "res://scenes/mainmenu/charactercreator/RaceSelection.tscn"
const CHARACTER_BUILD_SCENE = "res://scenes/mainmenu/charactercreator/CharacterBuild.tscn"

# Node references
@onready var back_button = $ButtonPanel/BackButton
@onready var randomize_button = $ButtonPanel/RandomizeButton
@onready var confirm_button = $ButtonPanel/ConfirmButton

# Character visualization references
@onready var character_portrait = $CharacterPreview/MarginContainer/VBoxContainer/PortraitPreview/FullBodyView
@onready var character_profile = $CharacterPreview/MarginContainer/VBoxContainer/PortraitPreview/VBoxContainer/ProfilePreview
@onready var sprite_preview = $CharacterPreview/MarginContainer/VBoxContainer/SpritePreview

# Tab container
@onready var tab_container = $ScrollContainer/SelectionMargin/TabContainer

# Holds all character appearance data
var character_data = {}
var current_visible_options = null

# Store the original sizes and positions of all body parts
var original_sizes = {}
var original_positions = {}
var min_scale = 0.5  # Minimum scale factor (half size)
var max_scale = 2.0  # Maximum scale factor (double size)

func _ready():
	# Connect button signals
	back_button.pressed.connect(_on_back_button_pressed)
	randomize_button.pressed.connect(_on_randomize_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	
	# If we're in edit mode, disable back button
	back_button.disabled = GlobalVars.edit_character_mode
	
	# Store original sizes and positions of all body parts
	_store_original_body_part_properties()
	
	# Connect all body part buttons to their respective handlers
	_connect_body_part_buttons()
	
	# Connect edit separetely checkboxes to their bodyparts
	_connect_edit_separately_checkboxes()
	
	# Connect all sliders to their value changed handlers
	_connect_all_sliders()
	
	# Hide all options containers initially
	_hide_all_options_containers()
	
	# Load character data if it exists
	if !GlobalVars.selected_character_id.is_empty():
		load_character_data()
	else:
		# This shouldn't happen, but handle it gracefully
		print("Error: No character selected")
		get_tree().change_scene_to_file(RACE_SELECTION_SCENE)

# Store the original size and position of all body parts for reference
func _store_original_body_part_properties():
	# Store portrait body parts
	_store_node_properties_recursive(character_portrait)
	
	# Store profile body parts
	_store_node_properties_recursive(character_profile)

# Recursively store properties for a node and its children
func _store_node_properties_recursive(node):
	if node is TextureRect:
		# Store original scale and position
		original_sizes[node.get_path()] = node.scale
		original_positions[node.get_path()] = node.position
	
	# Process children
	for child in node.get_children():
		_store_node_properties_recursive(child)

# Connect all body part buttons
func _connect_body_part_buttons():
	# Connect Head tab buttons
	var head_tab = tab_container.get_node_or_null("Head")
	if head_tab:
		var head_parts_panel = head_tab.get_node_or_null("HeadPartsPanel")
		if head_parts_panel:
			_connect_buttons_in_container(head_parts_panel)
	
	# Connect Body tab buttons
	var body_tab = tab_container.get_node_or_null("Body")
	if body_tab:
		var body_parts_panel = body_tab.get_node_or_null("BodyPartsPanel")
		if body_parts_panel:
			_connect_buttons_in_container(body_parts_panel)

# Connect buttons in a container
func _connect_buttons_in_container(container):
	for child in container.get_children():
		if child is VBoxContainer:
			# Find the button in this section
			var button = _find_button_in_container(child)
			if button:
				# Store the section path for later use
				button.pressed.connect(_on_body_part_button_pressed.bind(child))

# Connect "Edit Separately" checkboxes
func _connect_edit_separately_checkboxes():
	# Find all checkboxes that control separate editing
	var checkboxes = []
	
	# Search in Head tab
	var head_tab = tab_container.get_node_or_null("Head")
	if head_tab:
		checkboxes.append_array(_find_edit_separately_checkboxes(head_tab))
	
	# Search in Body tab
	var body_tab = tab_container.get_node_or_null("Body")
	if body_tab:
		checkboxes.append_array(_find_edit_separately_checkboxes(body_tab))
	
	# Connect each checkbox
	for checkbox in checkboxes:
		checkbox.toggled.connect(_on_edit_separately_toggled.bind(checkbox))
		
		# Make sure the separate containers are initially hidden
		var options_container = checkbox.get_parent()
		var body_part_name = _get_body_part_name_from_options(options_container)
		
		if !body_part_name.is_empty():
			var separate_container = options_container.get_node_or_null(body_part_name + "SeparateContainer")
			if separate_container:
				separate_container.visible = false
				
			var style_separate_container = options_container.get_node_or_null(body_part_name + "StyleSeperateContainer")
			if style_separate_container:
				style_separate_container.visible = false

# Connect all sliders to their value changed handlers
func _connect_all_sliders():
	# Connect sliders in Head tab
	var head_tab = tab_container.get_node_or_null("Head")
	if head_tab:
		_connect_sliders_in_container(head_tab)
	
	# Connect sliders in Body tab
	var body_tab = tab_container.get_node_or_null("Body")
	if body_tab:
		_connect_sliders_in_container(body_tab)

# Connect sliders in a container
func _connect_sliders_in_container(container):
	if !container:
		return
	
	# Recursively find all sliders
	for child in container.get_children():
		if child is HSlider:
			# Connect slider value changed signal
			child.value_changed.connect(_on_slider_value_changed.bind(child))
		elif child.get_child_count() > 0:
			_connect_sliders_in_container(child)

# Find all "Edit Separately" checkboxes in a container
func _find_edit_separately_checkboxes(container):
	var checkboxes = []
	
	if !container:
		return checkboxes
	
	# Recursively search for checkboxes with the name "EditSeparatelyBox"
	for child in container.get_children():
		if child is CheckBox and "EditSeparatelyBox" in child.name:
			checkboxes.append(child)
		elif child.get_child_count() > 0:
			checkboxes.append_array(_find_edit_separately_checkboxes(child))
	
	return checkboxes

# Find a button in a container
func _find_button_in_container(container):
	for child in container.get_children():
		if child is Button:
			return child
	return null

# Hide all options containers
func _hide_all_options_containers():
	# Find and hide options in the Head tab
	var head_tab = tab_container.get_node_or_null("Head")
	if head_tab:
		_hide_options_in_container(head_tab)
	
	# Find and hide options in the Body tab
	var body_tab = tab_container.get_node_or_null("Body")
	if body_tab:
		_hide_options_in_container(body_tab)

# Hide all options containers in a container
func _hide_options_in_container(container):
	if !container:
		return
	
	# Recursively search for containers with "Options" in their name
	for child in container.get_children():
		if child is Control and "Options" in child.name:
			child.visible = false
		elif child.get_child_count() > 0:
			_hide_options_in_container(child)

# Button signal handlers
func _on_back_button_pressed():
	# Return to race selection scene
	get_tree().change_scene_to_file(RACE_SELECTION_SCENE)

func _on_randomize_button_pressed():
	# Randomize character appearance parts (will implement in later step)
	randomize_character_parts()
	update_character_display()

func _on_confirm_button_pressed():
	# Save character appearance data
	save_character_data()
	
	# Proceed to character build scene
	get_tree().change_scene_to_file(CHARACTER_BUILD_SCENE)

# Body part button handlers
func _on_body_part_button_pressed(section_container):
	# Find options container in this section
	var options_container = null
	for child in section_container.get_children():
		if child is Control and "Options" in child.name:
			options_container = child
			break
	
	if options_container:
		# If this options container is already visible, hide it
		if options_container.visible:
			options_container.visible = false
			current_visible_options = null
		else:
			# Otherwise, hide the previously visible options (if any)
			if current_visible_options:
				current_visible_options.visible = false
			
			# Show this options container
			options_container.visible = true
			current_visible_options = options_container

# Edit Separately checkbox handler
func _on_edit_separately_toggled(toggled, checkbox):
	# Get the body part name from the parent container
	var options_container = checkbox.get_parent()
	var body_part_name = _get_body_part_name_from_options(options_container)
	
	if body_part_name.is_empty():
		print("Could not determine body part name")
		return
	
	# Find the combined and separate containers using standardized naming
	var combined_container = options_container.get_node_or_null(body_part_name + "CombinedContainer")
	var separate_container = options_container.get_node_or_null(body_part_name + "SeparateContainer")
	
	# Toggle main settings containers
	if combined_container and separate_container:
		combined_container.visible = !toggled
		separate_container.visible = toggled
	
	# Handle style containers if they exist
	var style_combined_container = options_container.get_node_or_null(body_part_name + "StyleCombinedContainer")
	var style_separate_container = options_container.get_node_or_null(body_part_name + "StyleSeparateContainer")
	
	# Toggle style containers if they exist
	if style_combined_container and style_separate_container:
		style_combined_container.visible = !toggled
		style_separate_container.visible = toggled

# Get the type of a slider (Width, Height, Position, etc.)
func _get_slider_type(slider):
	# First check if the slider's parent container name contains a type
	var parent = slider.get_parent()
	if parent:
		var parent_name = parent.name
		for type in ["Width", "Height", "Position", "Size", "Spacing"]:
			if type in parent_name:
				return type
	
	# If not found in parent name, check grandparent and other ancestors
	var current = parent
	while current:
		var name = current.name
		for type in ["Width", "Height", "Position", "Size", "Spacing"]:
			if type in name:
				return type
		current = current.get_parent()
	
	return ""

# Slider value changed handler
func _on_slider_value_changed(value, slider):
	# Get slider information
	var slider_type = _get_slider_type(slider)
	var body_part = _get_body_part_from_slider(slider)
	
	if body_part.is_empty() || slider_type.is_empty():
		return
	
	# Update the character model based on slider type
	if slider_type == "Width":
		_adjust_body_part_width(body_part, value)
	elif slider_type == "Height":
		_adjust_body_part_height(body_part, value)
	elif slider_type == "Position":
		_adjust_body_part_position(body_part, value)
	elif slider_type == "Spacing":
		_adjust_body_part_spacing(body_part, value)
	
	# For eye/ear/etc. controls that can be edited separately
	# Check if we need to sync values
	_handle_separate_editing_sync(slider)
	
	# Update character appearance data for saving
	_update_appearance_data(body_part, slider_type, value)

# Get the body part name from a slider
func _get_body_part_from_slider(slider):
	var current = slider
	var body_part = ""
	
	# Traverse up the hierarchy to find the body part name
	while current && body_part.is_empty():
		var parent_name = current.get_parent().name
		
		# Check for known body part names
		for part in ["Hair", "Head", "Eyes", "Ears", "Nose", "Mouth", "Chin", "Neck",
			"Torso", "Belly", "Arms", "Hands", "Legs", "Feet", "Back", "Tail"]:
			if part in parent_name:
				body_part = part
				break
		
		current = current.get_parent()
	
	return body_part

# Find and adjust body part nodes by name
func _find_body_part_nodes(body_part_name):
	var nodes = []
	
	# Search in portrait
	nodes.append_array(_find_nodes_by_partial_name(character_portrait, body_part_name))
	
	# Search in profile
	nodes.append_array(_find_nodes_by_partial_name(character_profile, body_part_name))
	
	return nodes

# Find nodes with a partial name match
func _find_nodes_by_partial_name(root_node, partial_name):
	var matching_nodes = []
	
	if partial_name in root_node.name:
		matching_nodes.append(root_node)
	
	for child in root_node.get_children():
		if partial_name in child.name:
			matching_nodes.append(child)
		
		# Recursively search in children
		matching_nodes.append_array(_find_nodes_by_partial_name(child, partial_name))
	
	return matching_nodes

# Adjust the width of body parts
func _adjust_body_part_width(body_part, value):
	var scale_factor = _calculate_scale_factor(value)
	var nodes = _find_body_part_nodes(body_part)
	
	for node in nodes:
		if node is TextureRect:
			var original_scale = original_sizes.get(node.get_path(), Vector2(1, 1))
			node.scale.x = original_scale.x * scale_factor
			
			# If the node has "L" or "R" in its name, adjust position to keep it aligned
			if "L" in node.name || "R" in node.name:
				_adjust_side_node_position(node)

# Adjust the height of body parts
func _adjust_body_part_height(body_part, value):
	var scale_factor = _calculate_scale_factor(value)
	var nodes = _find_body_part_nodes(body_part)
	
	for node in nodes:
		if node is TextureRect:
			var original_scale = original_sizes.get(node.get_path(), Vector2(1, 1))
			node.scale.y = original_scale.y * scale_factor

# Adjust position (up/down) of body parts
func _adjust_body_part_position(body_part, value):
	var position_offset = _calculate_position_offset(value)
	var nodes = _find_body_part_nodes(body_part)
	
	for node in nodes:
		if node is TextureRect:
			var original_position = original_positions.get(node.get_path(), Vector2(0, 0))
			node.position.y = original_position.y + position_offset

# Adjust spacing between paired body parts (eyes, ears, etc.)
func _adjust_body_part_spacing(body_part, value):
	var spacing_factor = _calculate_spacing_factor(value)
	var left_nodes = _find_nodes_by_partial_name(character_portrait, body_part + "L")
	left_nodes.append_array(_find_nodes_by_partial_name(character_profile, body_part + "L"))
	
	var right_nodes = _find_nodes_by_partial_name(character_portrait, body_part + "R")
	right_nodes.append_array(_find_nodes_by_partial_name(character_profile, body_part + "R"))
	
	for node in left_nodes:
		if node is TextureRect:
			var original_position = original_positions.get(node.get_path(), Vector2(0, 0))
			node.position.x = original_position.x - spacing_factor
	
	for node in right_nodes:
		if node is TextureRect:
			var original_position = original_positions.get(node.get_path(), Vector2(0, 0))
			node.position.x = original_position.x + spacing_factor

# Handle sync between combined and separate sliders
func _handle_separate_editing_sync(slider):
	var options_container = _find_parent_options_container(slider)
	if !options_container:
		return
	
	var edit_separately_box = _find_edit_separately_checkbox(options_container)
	var slider_type = _get_slider_type(slider)
	var body_part = _get_body_part_from_slider(slider)
	
	# Determine if we need to sync values
	if edit_separately_box:
		if edit_separately_box.button_pressed:
			# We're in separate mode, check if we need to update combined slider
			var is_left_slider = _is_left_slider(slider)
			var is_right_slider = _is_right_slider(slider)
			
			if (is_left_slider || is_right_slider) && slider_type:
				# Find the combined slider with the same type
				var combined_slider = _find_combined_slider(options_container, slider_type)
				if combined_slider:
					# If we're modifying both sliders to the same value, update combined slider too
					var other_slider = _find_opposite_slider(options_container, slider, is_left_slider)
					if other_slider && abs(other_slider.value - slider.value) < 0.001:
						combined_slider.value = slider.value
		else:
			# We're in combined mode, need to update both separate sliders
			var separate_container = _find_separate_container(options_container)
			if separate_container && slider_type:
				var left_slider = _find_left_slider(separate_container, slider_type)
				var right_slider = _find_right_slider(separate_container, slider_type)
				
				if left_slider:
					left_slider.value = slider.value
				if right_slider:
					right_slider.value = slider.value

# Find parent options container for a slider
func _find_parent_options_container(node):
	var current = node
	while current:
		if current is Control && "Options" in current.name:
			return current
		current = current.get_parent()
	return null

# Find the edit separately checkbox in an options container
func _find_edit_separately_checkbox(options_container):
	for child in options_container.get_children():
		if child is CheckBox && "EditSeparatelyBox" in child.name:
			return child
	return null

# Check if a slider is for a left body part
func _is_left_slider(slider):
	var current = slider
	while current:
		if "Left" in current.name:
			return true
		current = current.get_parent()
	return false

# Check if a slider is for a right body part
func _is_right_slider(slider):
	var current = slider
	while current:
		if "Right" in current.name:
			return true
		current = current.get_parent()
	return false

# Find the separate container in an options container
func _find_separate_container(options_container):
	var body_part_name = _get_body_part_name_from_options(options_container)
	if body_part_name.is_empty():
		return null
	
	return options_container.get_node_or_null(body_part_name + "SeparateContainer")

# Find a slider in the combined container
func _find_combined_slider(options_container, slider_type):
	var body_part_name = _get_body_part_name_from_options(options_container)
	if body_part_name.is_empty():
		return null
	
	var combined_container = options_container.get_node_or_null(body_part_name + "CombinedContainer")
	if !combined_container:
		return null
	
	return _find_slider_by_type(combined_container, slider_type)

# Find a slider in the left container by type
func _find_left_slider(separate_container, slider_type):
	for child in separate_container.get_children():
		if "Left" in child.name:
			return _find_slider_by_type(child, slider_type)
	return null

# Find a slider in the right container by type
func _find_right_slider(separate_container, slider_type):
	for child in separate_container.get_children():
		if "Right" in child.name:
			return _find_slider_by_type(child, slider_type)
	return null

# Find a slider by type in a container
func _find_slider_by_type(container, slider_type):
	for child in container.get_children():
		if child is HSlider && slider_type in child.get_parent().name:
			return child
		elif child.get_child_count() > 0:
			var slider = _find_slider_by_type(child, slider_type)
			if slider:
				return slider
	return null

# Find the opposite slider (left->right or right->left)
func _find_opposite_slider(options_container, slider, is_left):
	var separate_container = _find_separate_container(options_container)
	if !separate_container:
		return null
	
	var slider_type = _get_slider_type(slider)
	if slider_type.is_empty():
		return null
	
	if is_left:
		return _find_right_slider(separate_container, slider_type)
	else:
		return _find_left_slider(separate_container, slider_type)

# Calculate scale factor from slider value (50 = 1.0, 0 = 0.5, 100 = 2.0)
func _calculate_scale_factor(value):
	# Map slider range (0-100) to scale range (min_scale to max_scale)
	return lerp(min_scale, max_scale, value / 100.0)

# Calculate position offset from slider value (50 = 0px, 0 = -50px, 100 = 50px)
func _calculate_position_offset(value):
	# Map slider range (0-100) to position offset (-50px to 50px)
	return (value - 50) * 1.0  # 1.0 = pixels per slider unit

# Calculate spacing factor from slider value (50 = 0px, 0 = -50px, 100 = 50px)
func _calculate_spacing_factor(value):
	# Map slider range (0-100) to spacing offset (0px to 50px)
	return (value - 50) * 1.0  # 1.0 = pixels per slider unit

# Adjust position of side nodes (left/right parts) when their width changes
func _adjust_side_node_position(node):
	# If it's a left part, adjust position right
	if "L" in node.name:
		var original_position = original_positions.get(node.get_path(), Vector2(0, 0))
		node.position.x = original_position.x - (node.scale.x - 1.0) * node.texture.get_width() / 2
	# If it's a right part, adjust position left
	elif "R" in node.name:
		var original_position = original_positions.get(node.get_path(), Vector2(0, 0))
		node.position.x = original_position.x + (node.scale.x - 1.0) * node.texture.get_width() / 2

# Helper function to get the body part name from the options container
func _get_body_part_name_from_options(options_container):
	var name = options_container.name
	
	# Remove "Options" suffix to get the body part name
	if name.ends_with("Options"):
		return name.substr(0, name.length() - 7)
	
	return ""

# Update the appearance data for saving
func _update_appearance_data(body_part, slider_type, value):
	if !character_data.has("Appearance"):
		character_data["Appearance"] = {}
	
	if !character_data["Appearance"].has(body_part):
		character_data["Appearance"][body_part] = {}
	
	character_data["Appearance"][body_part][slider_type] = value

# Data handling functions
func load_character_data():
	var file_path = GlobalVars.CHARACTERS_DIR + GlobalVars.selected_character_id + ".json"
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			character_data = json.data
			update_character_display()
	else:
		print("Character file not found: ", file_path)

func save_character_data():
	var file_path = GlobalVars.CHARACTERS_DIR + GlobalVars.selected_character_id + ".json"
	
	# Ensure appearance data is set in character_data
	if !character_data.has("Appearance"):
		character_data["Appearance"] = {}
		
	# Save all appearance settings (will be populated in later steps)
	# ... (add code here later)
	
	# Write file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(character_data, "  ")
		file.store_string(json_text)
		file.close()
	else:
		print("Error saving character data")

# Character visualization functions
func update_character_display():
	# Update character model based on selected parts (will implement in later step)
	pass

func randomize_character_parts():
	# Randomize character parts (will implement in later step)
	pass
