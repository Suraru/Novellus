extends Control

# Scene paths for navigation
const RACE_SELECTION_SCENE = "res://scenes/mainmenu/charactercreator/RaceSelection.tscn"
const CHARACTER_BUILD_SCENE = "res://scenes/mainmenu/charactercreator/CharacterBuild.tscn"

# Node references
@onready var back_button = $ButtonPanel/BackButton
@onready var randomize_button = $ButtonPanel/RandomizeButton
@onready var confirm_button = $ButtonPanel/ConfirmButton

# Character visualization references
@onready var character_portrait = $CharacterPreview/MarginContainer/VBoxContainer/CharacterInfo/Portrait
@onready var sprite_preview = $CharacterPreview/MarginContainer/VBoxContainer/SpritePreview

# Tab container
@onready var tab_container = $ScrollContainer/SelectionMargin/TabContainer

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
	
	# Connect edit separetely checkboxes to their bodyparts
	_connect_edit_separately_checkboxes()
	
	# Hide all options containers initially
	_hide_all_options_containers()
	
	# Load character data if it exists
	if !GlobalVars.selected_character_id.is_empty():
		load_character_data()
	else:
		# This shouldn't happen, but handle it gracefully
		print("Error: No character selected")
		get_tree().change_scene_to_file(RACE_SELECTION_SCENE)

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

# Helper function to get the body part name from the options container
func _get_body_part_name_from_options(options_container):
	var name = options_container.name
	
	# Remove "Options" suffix to get the body part name
	if name.ends_with("Options"):
		return name.substr(0, name.length() - 7)
	
	return ""

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
