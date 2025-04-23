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
	# Find parent container
	var parent_container = checkbox.get_parent()
	
	# Find combined and separate containers in the parent
	var combined_container = null
	var separate_container = null
	
	for child in parent_container.get_children():
		if child is Control:
			if "Combined" in child.name:
				combined_container = child
			elif "Separate" in child.name:
				separate_container = child
	
	# Toggle visibility based on checkbox state
	if combined_container and separate_container:
		combined_container.visible = !toggled
		separate_container.visible = toggled

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
