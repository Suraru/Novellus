extends Control

# Scene paths for navigation
const RACE_SELECTION_SCENE = "res://scenes/mainmenu/charactercreator/RaceSelection.tscn"
const CHARACTER_BUILD_SCENE = "res://scenes/mainmenu/charactercreator/CharacterBuild.tscn"

# Node references
@onready var back_button = $ButtonPanel/BackButton
@onready var randomize_button = $ButtonPanel/RandomizeButton
@onready var confirm_button = $ButtonPanel/ConfirmButton

# Character visualization references
@onready var full_body_view = $CharacterPreview/MarginContainer/VBoxContainer/PortraitPreview/FullBodyView
@onready var profile_preview = $CharacterPreview/MarginContainer/VBoxContainer/PortraitPreview/VBoxContainer/ProfilePreview
@onready var sprite_preview = $CharacterPreview/MarginContainer/VBoxContainer/SpritePreview

# Tab container
@onready var tab_container = $ScrollContainer/SelectionMargin/TabContainer

# Dictionary to store original positions and scales
var original_properties = {}

# Holds all character appearance data
var character_data = {}
var current_visible_options = null

func _ready():
	# Connect button signals
	back_button.pressed.connect(_on_back_button_pressed)
	randomize_button.pressed.connect(_on_randomize_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	
	# If we're in edit mode, disable back button
	back_button.disabled = GlobalVars.edit_character_mode
	
	# Connect all body part buttons to their respective handlers
	_connect_body_part_buttons()
	
	# Connect edit separately checkboxes
	_connect_edit_separately_checkboxes()
	
	# Store original properties of all body parts
	_store_original_properties()
	
	# Connect all sliders to their respective handlers
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

# Store original properties of all body parts
func _store_original_properties():
	# Store head parts from full body view
	var head = full_body_view.get_node("Belly/Torso/Neck/Head")
	original_properties["Head"] = {
		"position": head.position,
		"scale": head.scale
	}
	
	# Eyes
	var eye_l = head.get_node("EyeL")
	var eye_r = head.get_node("EyeR")
	original_properties["Eyes"] = {
		"Left": {
			"position": eye_l.position,
			"scale": eye_l.scale
		},
		"Right": {
			"position": eye_r.position,
			"scale": eye_r.scale
		},
		"spacing": eye_r.position.x - eye_l.position.x
	}
	
	# Ears
	var ear_l = head.get_node("EarL")
	var ear_r = head.get_node("EarR")
	original_properties["Ears"] = {
		"Left": {
			"position": ear_l.position,
			"scale": ear_l.scale
		},
		"Right": {
			"position": ear_r.position,
			"scale": ear_r.scale
		},
		"spacing": ear_r.position.x - ear_l.position.x
	}
	
	# Nose
	var nose = head.get_node("Nose")
	original_properties["Nose"] = {
		"position": nose.position,
		"scale": nose.scale
	}
	
	# Mouth
	var mouth = head.get_node("Mouth")
	original_properties["Mouth"] = {
		"position": mouth.position,
		"scale": mouth.scale
	}
	
	# Chin
	var chin = head.get_node("Chin")
	original_properties["Chin"] = {
		"position": chin.position,
		"scale": chin.scale
	}
	
	# Neck
	var neck = full_body_view.get_node("Belly/Torso/Neck")
	original_properties["Neck"] = {
		"position": neck.position,
		"scale": neck.scale
	}
	
	# Torso
	var torso = full_body_view.get_node("Belly/Torso")
	original_properties["Torso"] = {
		"position": torso.position,
		"scale": torso.scale
	}
	
	# Belly
	var belly = full_body_view.get_node("Belly")
	original_properties["Belly"] = {
		"position": belly.position,
		"scale": belly.scale
	}
	
	# Arms
	var arm_l = torso.get_node("ArmL")
	var arm_r = torso.get_node("ArmR")
	original_properties["Arms"] = {
		"Left": {
			"position": arm_l.position,
			"scale": arm_l.scale
		},
		"Right": {
			"position": arm_r.position,
			"scale": arm_r.scale
		},
		"spacing": abs(arm_r.position.x - arm_l.position.x)
	}
	
	# Hands
	var hand_l = arm_l.get_node("HandL")
	var hand_r = arm_r.get_node("HandR")
	original_properties["Hands"] = {
		"Left": {
			"position": hand_l.position,
			"scale": hand_l.scale
		},
		"Right": {
			"position": hand_r.position,
			"scale": hand_r.scale
		},
		"spacing": 0  # Hands are attached to arms, so spacing is determined by arm position
	}
	
	# Legs
	var leg_l = belly.get_node("LegL")
	var leg_r = belly.get_node("LegR")
	original_properties["Legs"] = {
		"Left": {
			"position": leg_l.position,
			"scale": leg_l.scale
		},
		"Right": {
			"position": leg_r.position,
			"scale": leg_r.scale
		},
		"spacing": abs(leg_r.position.x - leg_l.position.x)
	}
	
	# Feet
	var foot_l = leg_l.get_node("FootL")
	var foot_r = leg_r.get_node("FootR")
	original_properties["Feet"] = {
		"Left": {
			"position": foot_l.position,
			"scale": foot_l.scale
		},
		"Right": {
			"position": foot_r.position,
			"scale": foot_r.scale
		},
		"spacing": 0  # Feet are attached to legs, so spacing is determined by leg position
	}
	
	# Store profile view parts
	var profile_head = profile_preview.get_node("Neck/Head")
	original_properties["Profile"] = {
		"Head": {
			"position": profile_head.position,
			"scale": profile_head.scale
		}
	}
	
	# Profile eyes
	var profile_eye_l = profile_head.get_node("EyeL")
	var profile_eye_r = profile_head.get_node("EyeR")
	original_properties["Profile"]["Eyes"] = {
		"Left": {
			"position": profile_eye_l.position,
			"scale": profile_eye_l.scale
		},
		"Right": {
			"position": profile_eye_r.position,
			"scale": profile_eye_r.scale
		},
		"spacing": profile_eye_r.position.x - profile_eye_l.position.x
	}
	
	# Profile ears
	var profile_ear_l = profile_head.get_node("EarL")
	var profile_ear_r = profile_head.get_node("EarR")
	original_properties["Profile"]["Ears"] = {
		"Left": {
			"position": profile_ear_l.position,
			"scale": profile_ear_l.scale
		},
		"Right": {
			"position": profile_ear_r.position,
			"scale": profile_ear_r.scale
		},
		"spacing": profile_ear_r.position.x - profile_ear_l.position.x
	}
	
	# Profile nose, mouth, chin
	original_properties["Profile"]["Nose"] = {
		"position": profile_head.get_node("Nose").position,
		"scale": profile_head.get_node("Nose").scale
	}
	
	original_properties["Profile"]["Mouth"] = {
		"position": profile_head.get_node("Mouth").position,
		"scale": profile_head.get_node("Mouth").scale
	}
	
	original_properties["Profile"]["Chin"] = {
		"position": profile_head.get_node("Chin").position,
		"scale": profile_head.get_node("Chin").scale
	}
	
	# Profile neck
	original_properties["Profile"]["Neck"] = {
		"position": profile_preview.get_node("Neck").position,
		"scale": profile_preview.get_node("Neck").scale
	}

# Connect all sliders
func _connect_all_sliders():
	# Head tab sliders
	var head_tab = tab_container.get_node("Head")
	if head_tab:
		_connect_sliders_in_container(head_tab)
	
	# Body tab sliders
	var body_tab = tab_container.get_node("Body")
	if body_tab:
		_connect_sliders_in_container(body_tab)

# Connect sliders in a container
func _connect_sliders_in_container(container):
	for child in container.get_children():
		if child is VBoxContainer or child is HBoxContainer or child is GridContainer:
			_connect_sliders_in_container(child)
		elif child is HSlider:
			# Identify the slider type and body part
			var parent = child.get_parent()
			var slider_type = ""
			var body_part = ""
			var is_separate = false
			var side = ""
			
			# Determine slider type from container name
			if "Width" in parent.name:
				slider_type = "Width"
			elif "Height" in parent.name:
				slider_type = "Height"
			elif "Position" in parent.name:
				slider_type = "Position"
			elif "Spacing" in parent.name:
				slider_type = "Spacing"
			
			# Determine if this is a separate control
			if "Left" in parent.get_parent().name:
				is_separate = true
				side = "Left"
			elif "Right" in parent.get_parent().name:
				is_separate = true
				side = "Right"
			
			# Determine the body part
			var current = parent
			while current != null and body_part.is_empty():
				var current_parent = current.get_parent()
				if current_parent is VBoxContainer and "Section" in current_parent.name:
					body_part = current_parent.name.replace("Section", "")
					break
				current = current_parent
			
			# Connect the appropriate signal
			if !body_part.is_empty() and !slider_type.is_empty():
				if slider_type == "Spacing":
					child.value_changed.connect(_on_spacing_slider_changed.bind(body_part))
				elif is_separate:
					child.value_changed.connect(_on_separate_slider_changed.bind(body_part, slider_type, side))
				else:
					child.value_changed.connect(_on_slider_changed.bind(body_part, slider_type))

# Connect body part buttons
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

# Connect edit separately checkboxes
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
				
			var style_separate_container = options_container.get_node_or_null(body_part_name + "StyleSeparateContainer")
			if style_separate_container:
				style_separate_container.visible = false

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
	# Randomize character appearance parts
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

# Slider signal handlers
func _on_slider_changed(value, body_part, property_type):
	print("Changing %s %s to %f" % [body_part, property_type, value])
	
	# Update body part in full body view
	_update_body_part(full_body_view, body_part, property_type, value)
	
	# Also update in profile view for head parts
	if body_part in ["Head", "Eyes", "Ears", "Nose", "Mouth", "Chin", "Neck"]:
		_update_body_part(profile_preview, body_part, property_type, value, true)
	
	# If this is a paired body part, update both sides
	if body_part in ["Eyes", "Ears", "Arms", "Hands", "Legs", "Feet"]:
		# Update the separate sliders to match
		_update_separate_sliders(body_part, property_type, value)
	
	# Store in character data
	if !character_data.has("Appearance"):
		character_data["Appearance"] = {}
	
	if !character_data["Appearance"].has(body_part):
		character_data["Appearance"][body_part] = {}
	
	character_data["Appearance"][body_part][property_type] = value

func _on_separate_slider_changed(value, body_part, property_type, side):
	print("Changing %s %s %s to %f" % [body_part, side, property_type, value])
	
	# Update body part in full body view
	_update_body_part(full_body_view, body_part, property_type, value, false, side)
	
	# Also update in profile view for head parts
	if body_part in ["Eyes", "Ears"]:
		_update_body_part(profile_preview, body_part, property_type, value, true, side)
	
	# Store in character data
	if !character_data.has("Appearance"):
		character_data["Appearance"] = {}
	
	if !character_data["Appearance"].has(body_part):
		character_data["Appearance"][body_part] = {}
	
	if !character_data["Appearance"][body_part].has(side):
		character_data["Appearance"][body_part][side] = {}
	
	character_data["Appearance"][body_part][side][property_type] = value

func _on_spacing_slider_changed(value, body_part):
	print("Changing %s spacing to %f" % [body_part, value])
	
	# Update spacing in full body view
	_update_spacing(full_body_view, body_part, value)
	
	# Also update in profile view for head parts
	if body_part in ["Eyes", "Ears"]:
		_update_spacing(profile_preview, body_part, value, true)
	
	# Store in character data
	if !character_data.has("Appearance"):
		character_data["Appearance"] = {}
	
	if !character_data["Appearance"].has(body_part):
		character_data["Appearance"][body_part] = {}
	
	character_data["Appearance"][body_part]["Spacing"] = value

# Update body part properties
func _update_body_part(root_node, body_part, property_type, value, is_profile = false, side = ""):
	# Calculate scale factor (0.5 to 2.0 with 1.0 at value 50)
	var scale_factor = 0.5 + (value / 100.0) * 1.5
	
	# Calculate position offset (-50 to 50 with 0 at value 50)
	var position_offset = value - 50.0
	
	# Get the appropriate node
	var node = null
	
	if is_profile:
		# Get node from profile view
		if body_part == "Head":
			node = root_node.get_node("Neck/Head")
		elif body_part == "Neck":
			node = root_node.get_node("Neck")
		elif body_part in ["Eyes", "Ears"]:
			if side == "Left":
				node = root_node.get_node("Neck/Head/%sL" % [body_part.substr(0, body_part.length() - 1)])
			elif side == "Right":
				node = root_node.get_node("Neck/Head/%sR" % [body_part.substr(0, body_part.length() - 1)])
			else:
				# Without a side specified, update both
				var left_node = root_node.get_node("Neck/Head/%sL" % [body_part.substr(0, body_part.length() - 1)])
				var right_node = root_node.get_node("Neck/Head/%sR" % [body_part.substr(0, body_part.length() - 1)])
				
				_update_node_property(left_node, body_part, "Left", property_type, scale_factor, position_offset, true)
				_update_node_property(right_node, body_part, "Right", property_type, scale_factor, position_offset, true)
				return
		elif body_part in ["Nose", "Mouth", "Chin"]:
			node = root_node.get_node("Neck/Head/%s" % [body_part])
	else:
		# Get node from full body view
		if body_part == "Head":
			node = root_node.get_node("Belly/Torso/Neck/Head")
		elif body_part == "Neck":
			node = root_node.get_node("Belly/Torso/Neck")
		elif body_part == "Torso":
			node = root_node.get_node("Belly/Torso")
		elif body_part == "Belly":
			node = root_node.get_node("Belly")
		elif body_part in ["Eyes", "Ears"]:
			if side == "Left":
				node = root_node.get_node("Belly/Torso/Neck/Head/%sL" % [body_part.substr(0, body_part.length() - 1)])
			elif side == "Right":
				node = root_node.get_node("Belly/Torso/Neck/Head/%sR" % [body_part.substr(0, body_part.length() - 1)])
			else:
				# Without a side specified, update both
				var left_node = root_node.get_node("Belly/Torso/Neck/Head/%sL" % [body_part.substr(0, body_part.length() - 1)])
				var right_node = root_node.get_node("Belly/Torso/Neck/Head/%sR" % [body_part.substr(0, body_part.length() - 1)])
				
				_update_node_property(left_node, body_part, "Left", property_type, scale_factor, position_offset)
				_update_node_property(right_node, body_part, "Right", property_type, scale_factor, position_offset)
				return
		elif body_part in ["Nose", "Mouth", "Chin"]:
			node = root_node.get_node("Belly/Torso/Neck/Head/%s" % [body_part])
		elif body_part == "Arms":
			if side == "Left":
				node = root_node.get_node("Belly/Torso/ArmL")
			elif side == "Right":
				node = root_node.get_node("Belly/Torso/ArmR")
			else:
				var left_node = root_node.get_node("Belly/Torso/ArmL")
				var right_node = root_node.get_node("Belly/Torso/ArmR")
				
				_update_node_property(left_node, body_part, "Left", property_type, scale_factor, position_offset)
				_update_node_property(right_node, body_part, "Right", property_type, scale_factor, position_offset)
				return
		elif body_part == "Hands":
			if side == "Left":
				node = root_node.get_node("Belly/Torso/ArmL/HandL")
			elif side == "Right":
				node = root_node.get_node("Belly/Torso/ArmR/HandR")
			else:
				var left_node = root_node.get_node("Belly/Torso/ArmL/HandL")
				var right_node = root_node.get_node("Belly/Torso/ArmR/HandR")
				
				_update_node_property(left_node, body_part, "Left", property_type, scale_factor, position_offset)
				_update_node_property(right_node, body_part, "Right", property_type, scale_factor, position_offset)
				return
		elif body_part == "Legs":
			if side == "Left":
				node = root_node.get_node("Belly/LegL")
			elif side == "Right":
				node = root_node.get_node("Belly/LegR")
			else:
				var left_node = root_node.get_node("Belly/LegL")
				var right_node = root_node.get_node("Belly/LegR")
				
				_update_node_property(left_node, body_part, "Left", property_type, scale_factor, position_offset)
				_update_node_property(right_node, body_part, "Right", property_type, scale_factor, position_offset)
				return
		elif body_part == "Feet":
			if side == "Left":
				node = root_node.get_node("Belly/LegL/FootL")
			elif side == "Right":
				node = root_node.get_node("Belly/LegR/FootR")
			else:
				var left_node = root_node.get_node("Belly/LegL/FootL")
				var right_node = root_node.get_node("Belly/LegR/FootR")
				
				_update_node_property(left_node, body_part, "Left", property_type, scale_factor, position_offset)
				_update_node_property(right_node, body_part, "Right", property_type, scale_factor, position_offset)
				return
	
	if node:
		_update_node_property(node, body_part, side, property_type, scale_factor, position_offset, is_profile)

# Helper function to update a node's property
func _update_node_property(node, body_part, side, property_type, scale_factor, position_offset, is_profile = false):
	# Get original properties
	var orig_props = original_properties
	
	if is_profile:
		orig_props = original_properties["Profile"]
	
	if body_part in ["Eyes", "Ears", "Arms", "Hands", "Legs", "Feet"] and !side.is_empty():
		# For paired body parts with a side
		if orig_props.has(body_part) and orig_props[body_part].has(side):
			var orig = orig_props[body_part][side]
			
			if property_type == "Width":
				node.scale.x = orig["scale"].x * scale_factor
			elif property_type == "Height":
				node.scale.y = orig["scale"].y * scale_factor
			elif property_type == "Position":
				node.position.y = orig["position"].y - position_offset
		else:
			print("Warning: Original properties not found for %s %s" % [body_part, side])
	else:
		# For single body parts
		if orig_props.has(body_part):
			var orig = orig_props[body_part]
			
			if property_type == "Width":
				node.scale.x = orig["scale"].x * scale_factor
			elif property_type == "Height":
				node.scale.y = orig["scale"].y * scale_factor
			elif property_type == "Position":
				node.position.y = orig["position"].y - position_offset
		else:
			print("Warning: Original properties not found for %s" % [body_part])

# Update spacing between paired body parts
func _update_spacing(root_node, body_part, value, is_profile = false):
	# Calculate spacing adjustment (-50 to +50 with 0 at value 50)
	var spacing_adjustment = value - 50.0
	
	# Update the spacing based on body part
	if body_part == "Eyes":
		if is_profile:
			var left_eye = root_node.get_node("Neck/Head/EyeL")
			var right_eye = root_node.get_node("Neck/Head/EyeR")
			
			var orig_left_pos = original_properties["Profile"]["Eyes"]["Left"]["position"]
			var orig_right_pos = original_properties["Profile"]["Eyes"]["Right"]["position"]
			
			left_eye.position.x = orig_left_pos.x - spacing_adjustment
			right_eye.position.x = orig_right_pos.x + spacing_adjustment
		else:
			var left_eye = root_node.get_node("Belly/Torso/Neck/Head/EyeL")
			var right_eye = root_node.get_node("Belly/Torso/Neck/Head/EyeR")
			
			var orig_left_pos = original_properties["Eyes"]["Left"]["position"]
			var orig_right_pos = original_properties["Eyes"]["Right"]["position"]
			
			left_eye.position.x = orig_left_pos.x - spacing_adjustment
			right_eye.position.x = orig_right_pos.x + spacing_adjustment
	
	elif body_part == "Ears":
		if is_profile:
			var left_ear = root_node.get_node("Neck/Head/EarL")
			var right_ear = root_node.get_node("Neck/Head/EarR")
			
			var orig_left_pos = original_properties["Profile"]["Ears"]["Left"]["position"]
			var orig_right_pos = original_properties["Profile"]["Ears"]["Right"]["position"]
			
			left_ear.position.x = orig_left_pos.x - spacing_adjustment
			right_ear.position.x = orig_right_pos.x + spacing_adjustment
		else:
			var left_ear = root_node.get_node("Belly/Torso/Neck/Head/EarL")
			var right_ear = root_node.get_node("Belly/Torso/Neck/Head/EarR")
			
			var orig_left_pos = original_properties["Ears"]["Left"]["position"]
			var orig_right_pos = original_properties["Ears"]["Right"]["position"]
			
			left_ear.position.x = orig_left_pos.x - spacing_adjustment
			right_ear.position.x = orig_right_pos.x + spacing_adjustment
	
	elif body_part == "Arms":
		var left_arm = root_node.get_node("Belly/Torso/ArmL")
		var right_arm = root_node.get_node("Belly/Torso/ArmR")
		
		var orig_left_pos = original_properties["Arms"]["Left"]["position"]
		var orig_right_pos = original_properties["Arms"]["Right"]["position"]
		
		left_arm.position.x = orig_left_pos.x - spacing_adjustment
		right_arm.position.x = orig_right_pos.x + spacing_adjustment
	
	elif body_part == "Legs":
		var left_leg = root_node.get_node("Belly/LegL")
		var right_leg = root_node.get_node("Belly/LegR")
		
		var orig_left_pos = original_properties["Legs"]["Left"]["position"]
		var orig_right_pos = original_properties["Legs"]["Right"]["position"]
		
		left_leg.position.x = orig_left_pos.x - spacing_adjustment
		right_leg.position.x = orig_right_pos.x + spacing_adjustment

# Update the separate sliders to match the combined slider value
func _update_separate_sliders(body_part, property_type, value):
	# Find the section for this body part
	var section = null
	var tab_container = $ScrollContainer/SelectionMargin/TabContainer
	
	var tab_name = ""
	if body_part in ["Head", "Eyes", "Ears", "Nose", "Mouth", "Chin", "Neck"]:
		tab_name = "Head"
	else:
		tab_name = "Body"
	
	var tab = tab_container.get_node(tab_name)
	if tab:
		var panel_name = tab_name + "PartsPanel"
		var panel = tab.get_node(panel_name)
		
		if panel:
			for child in panel.get_children():
				if child is VBoxContainer and body_part in child.name:
					section = child
					break
	
	if section:
		# Find the options container
		var options_container = null
		for child in section.get_children():
			if child is VBoxContainer and "Options" in child.name:
				options_container = child
				break
		
		if options_container:
			# Find the separate container
			var separate_container = options_container.get_node_or_null(body_part + "SeparateContainer")
			
			if separate_container:
				# Update both left and right sliders
				_update_side_slider(separate_container, "Left", property_type, value)
				_update_side_slider(separate_container, "Right", property_type, value)

# Helper to update a side slider
func _update_side_slider(separate_container, side, property_type, value):
	# Find the side container
	var side_container = null
	for child in separate_container.get_children():
		if child is Container and side in child.name:
			side_container = child
			break
	
	if side_container:
		# Find the property container
		var prop_container = null
		for child in side_container.get_children():
			if child is Container and property_type in child.name:
				prop_container = child
				break
		
		if prop_container:
			# Find the slider
			for child in prop_container.get_children():
				if child is HSlider:
					# Update the slider value without triggering the signal
					child.set_value_no_signal(value)
					break

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
			
			# Apply appearance settings if available
			if character_data.has("Appearance"):
				apply_appearance_settings(character_data["Appearance"])
	else:
		print("Character file not found: ", file_path)

func save_character_data():
	var file_path = GlobalVars.CHARACTERS_DIR + GlobalVars.selected_character_id + ".json"
	
	# Ensure appearance data is set in character_data
	if !character_data.has("Appearance"):
		character_data["Appearance"] = {}
	
	# Write file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(character_data, "  ")
		file.store_string(json_text)
		file.close()
	else:
		print("Error saving character data")

# Apply appearance settings from loaded data
func apply_appearance_settings(appearance_data):
	# Apply each body part setting
	for body_part in appearance_data:
		var part_data = appearance_data[body_part]
		
		# Handle paired body parts
		if body_part in ["Eyes", "Ears", "Arms", "Hands", "Legs", "Feet"]:
			# Apply common settings first
			if part_data.has("Width"):
				_update_body_part(full_body_view, body_part, "Width", part_data["Width"])
				if body_part in ["Eyes", "Ears"]:
					_update_body_part(profile_preview, body_part, "Width", part_data["Width"], true)
			
			if part_data.has("Height"):
				_update_body_part(full_body_view, body_part, "Height", part_data["Height"])
				if body_part in ["Eyes", "Ears"]:
					_update_body_part(profile_preview, body_part, "Height", part_data["Height"], true)
			
			if part_data.has("Position"):
				_update_body_part(full_body_view, body_part, "Position", part_data["Position"])
				if body_part in ["Eyes", "Ears"]:
					_update_body_part(profile_preview, body_part, "Position", part_data["Position"], true)
			
			if part_data.has("Spacing"):
				_update_spacing(full_body_view, body_part, part_data["Spacing"])
				if body_part in ["Eyes", "Ears"]:
					_update_spacing(profile_preview, body_part, part_data["Spacing"], true)
			
			# Apply side-specific settings if they exist
			if part_data.has("Left"):
				var left_data = part_data["Left"]
				
				if left_data.has("Width"):
					_update_body_part(full_body_view, body_part, "Width", left_data["Width"], false, "Left")
					if body_part in ["Eyes", "Ears"]:
						_update_body_part(profile_preview, body_part, "Width", left_data["Width"], true, "Left")
				
				if left_data.has("Height"):
					_update_body_part(full_body_view, body_part, "Height", left_data["Height"], false, "Left")
					if body_part in ["Eyes", "Ears"]:
						_update_body_part(profile_preview, body_part, "Height", left_data["Height"], true, "Left")
				
				if left_data.has("Position"):
					_update_body_part(full_body_view, body_part, "Position", left_data["Position"], false, "Left")
					if body_part in ["Eyes", "Ears"]:
						_update_body_part(profile_preview, body_part, "Position", left_data["Position"], true, "Left")
			
			if part_data.has("Right"):
				var right_data = part_data["Right"]
				
				if right_data.has("Width"):
					_update_body_part(full_body_view, body_part, "Width", right_data["Width"], false, "Right")
					if body_part in ["Eyes", "Ears"]:
						_update_body_part(profile_preview, body_part, "Width", right_data["Width"], true, "Right")
				
				if right_data.has("Height"):
					_update_body_part(full_body_view, body_part, "Height", right_data["Height"], false, "Right")
					if body_part in ["Eyes", "Ears"]:
						_update_body_part(profile_preview, body_part, "Height", right_data["Height"], true, "Right")
				
				if right_data.has("Position"):
					_update_body_part(full_body_view, body_part, "Position", right_data["Position"], false, "Right")
					if body_part in ["Eyes", "Ears"]:
						_update_body_part(profile_preview, body_part, "Position", right_data["Position"], true, "Right")
		else:
			# Handle single body parts
			if part_data.has("Width"):
				_update_body_part(full_body_view, body_part, "Width", part_data["Width"])
				if body_part in ["Head", "Nose", "Mouth", "Chin", "Neck"]:
					_update_body_part(profile_preview, body_part, "Width", part_data["Width"], true)
			
			if part_data.has("Height"):
				_update_body_part(full_body_view, body_part, "Height", part_data["Height"])
				if body_part in ["Head", "Nose", "Mouth", "Chin", "Neck"]:
					_update_body_part(profile_preview, body_part, "Height", part_data["Height"], true)
			
			if part_data.has("Position"):
				_update_body_part(full_body_view, body_part, "Position", part_data["Position"])
				if body_part in ["Head", "Nose", "Mouth", "Chin", "Neck"]:
					_update_body_part(profile_preview, body_part, "Position", part_data["Position"], true)

# Character visualization functions
func update_character_display():
	# Update based on character data
	if character_data.has("Appearance"):
		apply_appearance_settings(character_data["Appearance"])

# Randomization function
func randomize_character_parts():
	# Get list of all body parts
	var body_parts = ["Head", "Eyes", "Ears", "Nose", "Mouth", "Chin", "Neck", "Torso", "Belly", "Arms", "Hands", "Legs", "Feet"]
	
	# Randomize each part
	for body_part in body_parts:
		# Randomize width and height (25-75 range for moderate variations)
		var random_width = randi_range(25, 75)
		var random_height = randi_range(25, 75)
		
		# Apply randomized sizes
		_on_slider_changed(random_width, body_part, "Width")
		_on_slider_changed(random_height, body_part, "Height")
		
		# Randomize position for applicable parts
		if body_part in ["Head", "Eyes", "Nose", "Mouth", "Chin", "Ears", "Neck"]:
			var random_position = randi_range(25, 75)
			_on_slider_changed(random_position, body_part, "Position")
		
		# Randomize spacing for paired parts
		if body_part in ["Eyes", "Ears", "Arms", "Legs"]:
			var random_spacing = randi_range(25, 75)
			_on_spacing_slider_changed(random_spacing, body_part)
		
		# Sometimes make paired parts asymmetrical (20% chance)
		if body_part in ["Eyes", "Ears", "Arms", "Hands", "Legs", "Feet"] and randf() < 0.2:
			var left_width = randi_range(25, 75)
			var left_height = randi_range(25, 75)
			var right_width = randi_range(25, 75)
			var right_height = randi_range(25, 75)
			
			_on_separate_slider_changed(left_width, body_part, "Width", "Left")
			_on_separate_slider_changed(left_height, body_part, "Height", "Left")
			_on_separate_slider_changed(right_width, body_part, "Width", "Right")
			_on_separate_slider_changed(right_height, body_part, "Height", "Right")

# Helper function to get the body part name from the options container
func _get_body_part_name_from_options(options_container):
	var name = options_container.name
	
	# Remove "Options" suffix to get the body part name
	if name.ends_with("Options"):
		return name.substr(0, name.length() - 7)
	
	return ""
