extends Control

# Scene paths
const RACE_SELECTION_SCENE = "res://scenes/mainmenu/charactercreator/RaceSelection.tscn"
const CHARACTER_BUILD_SCENE = "res://scenes/mainmenu/charactercreator/CharacterBuild.tscn"

# Node references
@onready var back_button = $ButtonPanel/BackButton
@onready var randomize_button = $ButtonPanel/RandomizeButton
@onready var confirm_button = $ButtonPanel/ConfirmButton

# Tab references
@onready var tab_container = $ScrollContainer/SelectionMargin/TabContainer

# Character data
var character_data = {
	"head": {},
	"body": {},
	"colors": {},
	"details": {}
}

# Section trackers
var active_section = ""
var section_nodes = {}

# Arrays to store paired body parts checkboxes
var separate_edit_checkboxes = {}

func _ready():
	# Connect button signals
	back_button.pressed.connect(_on_back_button_pressed)
	randomize_button.pressed.connect(_on_randomize_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	
	# Setup all sections for each tab
	_setup_head_sections()
	_setup_body_sections()
	_setup_colors_sections()
	_setup_details_sections()

# Setup functions
func _setup_head_sections():
	var head_panel = tab_container.get_node("Head/HeadPartsPanel")
	_setup_collapsible_sections(head_panel, "head")
	
	# Setup separate edit checkboxes for applicable head parts
	_setup_separate_edit_checkboxes(head_panel, "Eyes")
	_setup_separate_edit_checkboxes(head_panel, "Ears")

func _setup_body_sections():
	var body_panel = tab_container.get_node("Body/BodyPartsPanel")
	_setup_collapsible_sections(body_panel, "body")
	
	# Setup separate edit checkboxes for applicable body parts
	_setup_separate_edit_checkboxes(body_panel, "Arms")
	_setup_separate_edit_checkboxes(body_panel, "Hands")
	_setup_separate_edit_checkboxes(body_panel, "Legs")
	_setup_separate_edit_checkboxes(body_panel, "Feet")

func _setup_colors_sections():
	var colors_panel = tab_container.get_node("Colors/ColorsPanel")
	
	# Setup eye color separate checkbox
	var eye_separate_checkbox = colors_panel.get_node("EyeColorSection/EditSeparatelyBox")
	if eye_separate_checkbox:
		eye_separate_checkbox.toggled.connect(_on_eye_color_separate_toggled)
		separate_edit_checkboxes["EyeColor"] = {
			"checkbox": eye_separate_checkbox,
			"combined": colors_panel.get_node("EyeColorSection/EyesColorCombinedGrid"),
			"separate": colors_panel.get_node("EyeColorSection/EyesColorSeparateContainer")
		}
	
	# Connect color buttons
	_connect_color_buttons(colors_panel.get_node("HairColorSection/HairColorGrid"), "hair")
	_connect_color_buttons(colors_panel.get_node("SkinColorSection/SkinColorGrid"), "skin")
	_connect_color_buttons(colors_panel.get_node("EyeColorSection/EyesColorCombinedGrid"), "eye")
	_connect_color_buttons(colors_panel.get_node("DetailColorSection/DetailColorGrid"), "detail")
	
	# Connect separate eye color buttons
	if colors_panel.get_node("EyeColorSection/EyesColorSeparateContainer/LeftEyeContainer/LeftEyeGrid"):
		_connect_color_buttons(
			colors_panel.get_node("EyeColorSection/EyesColorSeparateContainer/LeftEyeContainer/LeftEyeGrid"), 
			"eye_left"
		)
	
	if colors_panel.get_node("EyeColorSection/EyesColorSeparateContainer/RightEyeContainer/RightEyeGrid"):
		_connect_color_buttons(
			colors_panel.get_node("EyeColorSection/EyesColorSeparateContainer/RightEyeContainer/RightEyeGrid"), 
			"eye_right"
		)

func _setup_details_sections():
	var details_panel = tab_container.get_node("Details/DetailsPanel")
	
	# Connect tattoo buttons
	var tattoos_grid = details_panel.get_node("TattoosSection/TattoosGrid")
	if tattoos_grid:
		for button in tattoos_grid.get_children():
			button.pressed.connect(_on_tattoo_selected.bind(button.name))
	
	# Connect scar buttons
	var scars_grid = details_panel.get_node("ScarsSection/ScarsGrid")
	if scars_grid:
		for button in scars_grid.get_children():
			button.pressed.connect(_on_scar_selected.bind(button.name))
	
	# Connect pattern buttons
	var patterns_grid = details_panel.get_node("PatternsSection/PatternsGrid")
	if patterns_grid:
		for button in patterns_grid.get_children():
			button.pressed.connect(_on_pattern_selected.bind(button.name))
	
	# Connect sliders for details
	_connect_sliders(details_panel.get_node("TattoosSection/TattooOptionsContainer"), "tattoo")
	_connect_sliders(details_panel.get_node("ScarsSection/ScarOptionsContainer"), "scar")  
	_connect_sliders(details_panel.get_node("PatternsSection/PatternOptionsContainer"), "pattern")

func _setup_collapsible_sections(panel, category):
	# For each section with a button and options
	for section in panel.get_children():
		if section is VBoxContainer:
			# Get button node (might have different names in different sections)
			var button = null
			for child in section.get_children():
				if child is Button:
					button = child
					break
			
			if button == null:
				continue
			
			# Get options container
			var options = null
			for child in section.get_children():
				if child is VBoxContainer and "Options" in child.name:
					options = child
					break
					
			if options == null:
				continue
				
			# Add to section trackers
			section_nodes[section.name] = {
				"button": button,
				"options": options,
				"category": category
			}
			
			# Connect button to toggle function
			button.pressed.connect(_toggle_section_options.bind(section.name))
			
			# Connect sliders for this section
			for sliders_container in options.get_children():
				if sliders_container is VBoxContainer and "Sliders" in sliders_container.name:
					_connect_sliders(sliders_container, section.name.replace("Section", "").to_lower())
			
			# Connect style buttons if they exist
			for container in options.get_children():
				if container is HBoxContainer and "StyleContainer" in container.name:
					var preview_grid = container.get_node_or_null("StylePreview")
					if preview_grid:
						for button_node in preview_grid.get_children():
							if button_node is TextureButton:
								button_node.pressed.connect(_on_style_selected.bind(section.name, button_node.name))

func _setup_separate_edit_checkboxes(panel, part_name):
	var section = panel.get_node_or_null(part_name + "Section")
	if not section:
		return
		
	var options = section.get_node_or_null(part_name + "Options")
	if not options:
		return
	
	var checkbox = options.get_node_or_null("EditSeparatelyBox")
	if not checkbox:
		return
		
	var combined = options.get_node_or_null(part_name + "CombinedContainer")
	var separate = options.get_node_or_null(part_name + "SeparateContainer")
	
	# Also handle style containers if they exist
	var style_combined = options.get_node_or_null(part_name + "StyleContainer")
	var style_separate = options.get_node_or_null(part_name + "StyleSeperateContainer")
	
	if checkbox and combined and separate:
		separate_edit_checkboxes[part_name] = {
			"checkbox": checkbox,
			"combined": combined,
			"separate": separate,
			"style_combined": style_combined,
			"style_separate": style_separate
		}
		
		checkbox.toggled.connect(_on_separate_edit_toggled.bind(part_name))

func _connect_color_buttons(grid, color_type):
	if grid:
		for button in grid.get_children():
			if button is ColorPickerButton:
				button.color_changed.connect(_on_color_changed.bind(color_type, button.name))

func _connect_sliders(container, slider_prefix):
	if not container:
		return
		
	for child in container.get_children():
		if child is VBoxContainer:
			var slider = child.get_node_or_null(child.name.replace("Container", "Slider"))
			if slider and slider is HSlider:
				var param_name = child.name.replace("Container", "").to_lower()
				slider.value_changed.connect(_on_slider_value_changed.bind(slider_prefix, param_name))

# Button event handlers
func _on_back_button_pressed():
	# Go back to race selection
	get_tree().change_scene_to_file(RACE_SELECTION_SCENE)

func _on_randomize_button_pressed():
	# Implement randomization logic
	# For all sliders, set to random values
	_randomize_character()
	
	# Update visual representation
	_update_character_preview()

func _on_confirm_button_pressed():
	# Save character data
	_save_character_data()
	
	# Go to character build
	get_tree().change_scene_to_file(CHARACTER_BUILD_SCENE)

# Section toggling
func _toggle_section_options(section_name):
	# If we're trying to open the same section that's already open, close it
	if active_section == section_name and section_nodes[section_name]["options"].visible:
		section_nodes[section_name]["options"].visible = false
		active_section = ""
		return
	
	# Close currently open section if there is one
	if active_section != "" and active_section in section_nodes:
		section_nodes[active_section]["options"].visible = false
	
	# Open the requested section
	active_section = section_name
	section_nodes[section_name]["options"].visible = true

# Separate edit toggling
func _on_separate_edit_toggled(toggled, part_name):
	var part_data = separate_edit_checkboxes[part_name]
	
	# Toggle visibility of combined vs separate containers
	part_data["combined"].visible = !toggled
	part_data["separate"].visible = toggled
	
	# Also toggle style containers if they exist
	if part_data["style_combined"] and part_data["style_separate"]:
		part_data["style_combined"].visible = !toggled
		part_data["style_separate"].visible = toggled
	
	# Store the setting in character data
	var category = "head" if tab_container.current_tab == 0 else "body"
	character_data[category][part_name.to_lower() + "_separate"] = toggled
	
	# Update character preview
	_update_character_preview()

# Eye color separate toggling
func _on_eye_color_separate_toggled(toggled):
	var eye_data = separate_edit_checkboxes["EyeColor"]
	
	# Toggle visibility of combined vs separate containers
	eye_data["combined"].visible = !toggled
	eye_data["separate"].visible = toggled
	
	# Store the setting in character data
	character_data["colors"]["eye_separate"] = toggled
	
	# Update character preview
	_update_character_preview()

# Slider value changed
func _on_slider_value_changed(value, slider_prefix, param_name):
	# Determine which category this belongs to based on the active tab
	var category = "head"
	if tab_container.current_tab == 1:
		category = "body"
	elif tab_container.current_tab == 3:
		category = "details"
	
	# For parameters like "left_width" or "right_height", we need to handle them specially
	if "left_" in param_name or "right_" in param_name:
		var side = "left" if "left_" in param_name else "right"
		var actual_param = param_name.replace(side + "_", "")
		
		# Make sure the part exists in the character data
		if not slider_prefix in character_data[category]:
			character_data[category][slider_prefix] = {}
		
		if not side in character_data[category][slider_prefix]:
			character_data[category][slider_prefix][side] = {}
			
		character_data[category][slider_prefix][side][actual_param] = value
	else:
		# Make sure the part exists in the character data
		if not slider_prefix in character_data[category]:
			character_data[category][slider_prefix] = {}
			
		character_data[category][slider_prefix][param_name] = value
	
	# Update character preview
	_update_character_preview()

# Color changed
func _on_color_changed(color, color_type, button_name):
	# For eye color, we need to check if we're in separate mode
	if color_type == "eye_left" or color_type == "eye_right":
		var side = "left" if color_type == "eye_left" else "right"
		
		if not "eye" in character_data["colors"]:
			character_data["colors"]["eye"] = {}
			
		if not side in character_data["colors"]["eye"]:
			character_data["colors"]["eye"][side] = {}
			
		character_data["colors"]["eye"][side] = color
	else:
		character_data["colors"][color_type] = color
	
	# Update character preview
	_update_character_preview()

# Style selected
func _on_style_selected(section_name, style_name):
	var part_name = section_name.replace("Section", "").to_lower()
	var category = section_nodes[section_name]["category"]
	
	# Extract style number from the name
	var style_number = style_name.replace(part_name.capitalize() + "Style", "")
	
	# Store in character data
	if not part_name in character_data[category]:
		character_data[category][part_name] = {}
		
	character_data[category][part_name]["style"] = int(style_number)
	
	# Update character preview
	_update_character_preview()

# Detail selection handlers
func _on_tattoo_selected(tattoo_name):
	_handle_detail_selection("tattoo", tattoo_name)

func _on_scar_selected(scar_name):
	_handle_detail_selection("scar", scar_name)

func _on_pattern_selected(pattern_name):
	_handle_detail_selection("pattern", pattern_name)

func _handle_detail_selection(detail_type, item_name):
	# Extract item number from the name or check if it's "None"
	var item_number = -1
	if "None" in item_name:
		item_number = 0
	else:
		item_number = int(item_name.replace(detail_type.capitalize(), ""))
	
	# Store in character data
	if not detail_type in character_data["details"]:
		character_data["details"][detail_type] = {}
		
	character_data["details"][detail_type]["type"] = item_number
	
	# Highlight the selected button and reset others
	var grid = tab_container.get_node("Details/DetailsPanel/" + detail_type.capitalize() + "sSection/" + detail_type.capitalize() + "sGrid")
	if grid:
		for button in grid.get_children():
			button.modulate = Color(1, 1, 1, 1)  # Reset all to default
		
		var selected = grid.get_node(item_name)
		if selected:
			selected.modulate = Color(0.8, 0.9, 1, 1)  # Highlight selected
	
	# Update character preview
	_update_character_preview()

# Utility functions
func _randomize_character():
	# Randomize all sliders
	_randomize_sliders_in_tab("Head")
	_randomize_sliders_in_tab("Body")
	
	# Randomize colors
	_randomize_colors()
	
	# Randomize details
	_randomize_details()
	
	# Randomize separate part settings with a 30% chance
	for part_name in separate_edit_checkboxes.keys():
		if part_name != "EyeColor":  # Handle eye color separately
			var checkbox = separate_edit_checkboxes[part_name]["checkbox"]
			var should_separate = randf() < 0.3  # 30% chance
			checkbox.button_pressed = should_separate
			_on_separate_edit_toggled(should_separate, part_name)
	
	# Randomize eye color separation with a 20% chance
	var eye_checkbox = separate_edit_checkboxes["EyeColor"]["checkbox"]
	var should_separate_eyes = randf() < 0.2  # 20% chance
	eye_checkbox.button_pressed = should_separate_eyes
	_on_eye_color_separate_toggled(should_separate_eyes)

func _randomize_sliders_in_tab(tab_name):
	var panel_path = ""
	if tab_name == "Head":
		panel_path = tab_name + "/HeadPartsPanel"
	elif tab_name == "Body": 
		panel_path = tab_name + "/BodyPartsPanel"
	else:
		panel_path = tab_name + "/BodyPartsPanel"  # Default fallback
	
	var panel = tab_container.get_node(panel_path)
	
	if panel:
		for section in panel.get_children():
			if section is VBoxContainer:
				var options = section.get_node_or_null(section.name.replace("Section", "Options"))
				if options:
					# Find and randomize all sliders
					_randomize_sliders_in_container(options)

func _randomize_sliders_in_container(container):
	for child in container.get_children():
		if child is VBoxContainer:
			_randomize_sliders_in_container(child)
		elif child is HBoxContainer:
			_randomize_sliders_in_container(child)
		elif child is HSlider:
			child.value = randf_range(child.min_value, child.max_value)

func _randomize_colors():
	var colors_panel = tab_container.get_node("Colors/ColorsPanel")
	
	# Randomize hair color
	var hair_grid = colors_panel.get_node("HairColorSection/HairColorGrid")
	if hair_grid and hair_grid.get_child_count() > 0:
		var random_hair = hair_grid.get_child(randi() % hair_grid.get_child_count())
		random_hair.button_pressed = true
		_on_color_changed(random_hair.color, "hair", random_hair.name)
	
	# Randomize skin color
	var skin_grid = colors_panel.get_node("SkinColorSection/SkinColorGrid")
	if skin_grid and skin_grid.get_child_count() > 0:
		var random_skin = skin_grid.get_child(randi() % skin_grid.get_child_count())
		random_skin.button_pressed = true
		_on_color_changed(random_skin.color, "skin", random_skin.name)
	
	# Randomize eye color
	var eye_grid = colors_panel.get_node("EyeColorSection/EyesColorCombinedGrid")
	if eye_grid and eye_grid.get_child_count() > 0:
		var random_eye = eye_grid.get_child(randi() % eye_grid.get_child_count())
		random_eye.button_pressed = true
		_on_color_changed(random_eye.color, "eye", random_eye.name)
	
	# Randomize detail color
	var detail_grid = colors_panel.get_node("DetailColorSection/DetailColorGrid")
	if detail_grid and detail_grid.get_child_count() > 0:
		var random_detail = detail_grid.get_child(randi() % detail_grid.get_child_count())
		random_detail.button_pressed = true
		_on_color_changed(random_detail.color, "detail", random_detail.name)

func _randomize_details():
	var details_panel = tab_container.get_node("Details/DetailsPanel")
	
	# 50% chance of having a tattoo
	if randf() < 0.5:
		var tattoos_grid = details_panel.get_node("TattoosSection/TattoosGrid")
		if tattoos_grid:
			# Skip the first "None" button
			var random_index = 1 + randi() % (tattoos_grid.get_child_count() - 1)
			if random_index < tattoos_grid.get_child_count():
				var random_tattoo = tattoos_grid.get_child(random_index)
				_on_tattoo_selected(random_tattoo.name)
	else:
		# Select "None"
		_on_tattoo_selected("TattooNone")
	
	# 30% chance of having a scar
	if randf() < 0.3:
		var scars_grid = details_panel.get_node("ScarsSection/ScarsGrid")
		if scars_grid:
			# Skip the first "None" button
			var random_index = 1 + randi() % (scars_grid.get_child_count() - 1)
			if random_index < scars_grid.get_child_count():
				var random_scar = scars_grid.get_child(random_index)
				_on_scar_selected(random_scar.name)
	else:
		# Select "None"
		_on_scar_selected("ScarNone")
	
	# 20% chance of having a pattern
	if randf() < 0.2:
		var patterns_grid = details_panel.get_node("PatternsSection/PatternsGrid")
		if patterns_grid:
			# Skip the first "None" button
			var random_index = 1 + randi() % (patterns_grid.get_child_count() - 1)
			if random_index < patterns_grid.get_child_count():
				var random_pattern = patterns_grid.get_child(random_index)
				_on_pattern_selected(random_pattern.name)
	else:
		# Select "None"
		_on_pattern_selected("PatternNone")

func _update_character_preview():
	# This will be implemented later when the character preview system is ready
	# For now, just print the character data for debugging
	print("Character data updated: ", character_data)

func _save_character_data():
	# This will save the character data to be used in other scenes
	# For now, just print that we're saving
	print("Saving character data: ", character_data)
	
	# In a real implementation, you might save to a global state or to a file
	# Singleton.character_data = character_data
