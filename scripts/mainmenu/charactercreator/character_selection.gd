extends Control

@onready var background = $Characterbg
@onready var character_list = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/LeftPanel/CharacterListContainer/CharacterList
@onready var edit_button = $MainContainer/ContentPanel/VBoxContainer/ButtonPanel/EditButton
@onready var delete_button = $MainContainer/ContentPanel/VBoxContainer/ButtonPanel/DeleteButton
@onready var start_button = $MainContainer/ContentPanel/VBoxContainer/ButtonPanel/StartButton
@onready var back_button = $MainContainer/ContentPanel/VBoxContainer/ButtonPanel/BackButton
@onready var create_button = $MainContainer/ContentPanel/VBoxContainer/ButtonPanel/CreateButton

# Sprite preview references
@onready var portrait = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterInfo/Portrait
@onready var front = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/SpritePreview/Front
@onready var back = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/SpritePreview/Back
@onready var left = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/SpritePreview/Left
@onready var right = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/SpritePreview/Right

# Character info references
@onready var character_name = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterName
@onready var race_value = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterInfo/InfoContainer/StatsContainer/RaceValue
@onready var age_value = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterInfo/InfoContainer/StatsContainer/AgeValue
@onready var gender_value = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterInfo/InfoContainer/StatsContainer/GenderValue
@onready var location_value = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterInfo/InfoContainer/StatsContainer/LocationValue
@onready var status_value = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterInfo/InfoContainer/StatsContainer/StatusValue

# Pagination controls
@onready var page_indicator = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/LeftPanel/CharacterListContainer/PaginationContainer/PageIndicator
@onready var prev_page_button = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/LeftPanel/CharacterListContainer/PaginationContainer/PrevPageButton
@onready var next_page_button = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/LeftPanel/CharacterListContainer/PaginationContainer/NextPageButton

var characters = []
var selected_character_id := ""

# Pagination variables
var items_per_page := 8
var current_page := 0 
var total_pages := 1

# Store the save path if we're coming from the save creation screen
var coming_from_save_path := ""

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	
	# Connect signals
	character_list.item_selected.connect(_on_character_selected)
	edit_button.pressed.connect(_on_edit_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	create_button.pressed.connect(_on_create_pressed)
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	prev_page_button.pressed.connect(_on_prev_page_pressed)
	next_page_button.pressed.connect(_on_next_page_pressed)
	
	# Check if we're coming from a save creation
	_check_if_from_save_creation()
	
	# Load characters and setup pagination
	_load_characters()
	_update_pagination_ui()

func _check_if_from_save_creation():
	# Check if we're coming from a save file creation/edit
	if Engine.has_singleton("GlobalState"):
		# Check if GlobalState has the current_save_path variable and it's not empty
		if "current_save_path" in GlobalState:
			coming_from_save_path = GlobalState.current_save_path
			
			# If we have a save path, update the Start button text
			if coming_from_save_path != "":
				print("DEBUG: Coming from save creation with save path: " + coming_from_save_path)
				start_button.text = "Select Character"

func _on_viewport_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Handle background scaling
	var bg_texture_size = background.texture.get_size()
	var bg_scale_x = viewport_size.x / bg_texture_size.x
	var bg_scale_y = viewport_size.y / bg_texture_size.y
	var scaling_factor = max(bg_scale_x, bg_scale_y)
	
	background.scale = Vector2(scaling_factor, scaling_factor)
	background.position = Vector2.ZERO
	
	# Wait a frame to get accurate size measurements
	await get_tree().process_frame
	
	# Recalculate items that can fit based on available height
	# Each item is now 3 lines of text with a separator
	var list_height = character_list.get_rect().size.y
	var item_height = 80  # Approximate height of a 3-line item in the list with separation
	items_per_page = max(1, int(list_height / item_height))
	
	# Refresh pagination if needed
	if characters.size() > 0:
		_update_pagination()

func _load_characters():
	character_list.clear()
	characters.clear()
	selected_character_id = ""
	_reset_ui_state()

	# Get all characters
	var all_characters = GlobalState.get_all_characters()
	
	if all_characters.size() == 0:
		character_list.add_item("You have no saved characters! Create one to begin.")
		character_list.set_item_disabled(0, true)
		_reset_character_info()
	else:
		# Sort characters alphabetically by name
		all_characters.sort_custom(func(a, b): return a.get("fullname", "") < b.get("fullname", ""))
		
		# Store characters
		for character in all_characters:
			characters.append({
				"data": character,
				"id": character.id
			})
		
		_update_pagination()

func _update_pagination():
	# Calculate if we need pagination at all
	total_pages = ceil(float(characters.size()) / float(items_per_page))
	
	# Only enable pagination if there are multiple pages
	if total_pages > 1:
		prev_page_button.visible = true
		next_page_button.visible = true
		page_indicator.visible = true
	else:
		# Hide pagination controls if only one page
		prev_page_button.visible = false
		next_page_button.visible = false
		page_indicator.visible = false
		current_page = 0
	
	current_page = clamp(current_page, 0, max(0, total_pages - 1))
	
	# Refresh character list for current page
	_display_current_page()
	_update_pagination_ui()

func _display_current_page():
	character_list.clear()
	
	var start_index = current_page * items_per_page
	var end_index = min(start_index + items_per_page, characters.size())
	
	for i in range(start_index, end_index):
		var char_data = characters[i].data
		var character_name = char_data.get("fullname", "Unknown")
		var character_race = char_data.get("race", "Unknown")
		var character_age = str(char_data.get("age", "??"))
		var character_location = char_data.get("location", "Unknown")
		
		var label = "%s\nRace: %s | Age: %s | %s" % [
			character_name,
			character_race,
			character_age,
			character_location
		]
		
		character_list.add_item(label)

func _update_pagination_ui():
	# Update page indicator text
	if total_pages > 0:
		page_indicator.text = "Page %d/%d" % [current_page + 1, total_pages]
	else:
		page_indicator.text = "Page 1/1"
	
	# Enable/disable pagination buttons
	prev_page_button.disabled = (current_page <= 0)
	next_page_button.disabled = (current_page >= total_pages - 1 || total_pages <= 1)

func _on_prev_page_pressed():
	if current_page > 0:
		current_page -= 1
		_display_current_page()
		_update_pagination_ui()

func _on_next_page_pressed():
	if current_page < total_pages - 1:
		current_page += 1
		_display_current_page()
		_update_pagination_ui()

func _on_character_selected(index):
	var actual_index = current_page * items_per_page + index
	
	if actual_index < characters.size():
		var character_id = characters[actual_index].id
		edit_button.disabled = false
		delete_button.disabled = false
		start_button.disabled = false
		
		# Set the active character in GlobalState
		selected_character_id = characters[actual_index].id
		GlobalState.set_active_character(character_id)
		
		_update_character_info(characters[actual_index].data)
	else:
		_reset_ui_state()

func _update_character_info(char_data):
	# Update character info UI
	character_name.text = char_data.get("fullname", "Unknown Character")
	race_value.text = char_data.get("race", "-")
	age_value.text = str(char_data.get("age", "-"))
	gender_value.text = char_data.get("gender", "-")
	location_value.text = char_data.get("location", "-")
	status_value.text = char_data.get("status", "-")
	
	# Load portrait if available
	if char_data.has("portrait_path") and FileAccess.file_exists(char_data.portrait_path):
		var portrait_texture = load(char_data.portrait_path)
		if portrait_texture:
			portrait.texture = portrait_texture

func _reset_character_info():
	character_name.text = "Select a Character"
	race_value.text = "-"
	age_value.text = "-"
	gender_value.text = "-"
	location_value.text = "-"
	status_value.text = "-"
	
	# Clear portrait and sprite previews
	portrait.texture = null
	front.texture = null
	back.texture = null
	left.texture = null
	right.texture = null

func _reset_ui_state():
	edit_button.disabled = true
	delete_button.disabled = true
	start_button.disabled = true
	_reset_character_info()

func _on_edit_pressed():
	# The active character is already set, just navigate to the appearance screen
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/ChangeAppearance.tscn")


func _on_delete_pressed():
	# Get the active character ID
	var character_id = GlobalState.active_character_id
	
	if character_id.is_empty():
		return
	
	# Create a confirmation dialog
	var confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.title = "Confirm Deletion"
	confirmation_dialog.dialog_text = "Are you sure you want to delete this character?"
	confirmation_dialog.confirmed.connect(func():
		# Remove character from save
		GlobalState.remove_character_from_save(character_id)
		
		# Reload characters and reset UI
		_load_characters()
		_reset_ui_state()
	)
	
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()

# For _on_create_pressed() function in character_selection.gd
func _on_create_pressed():
	# Clear active character so a new one will be created
	GlobalState.set_active_character("")
	
	# No need to set is_editing_character anymore
	# Just navigate to the race selection screen
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/RaceSelection.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/GameStart.tscn")

func _on_start_pressed():
	print("Start button pressed with character_id: ", selected_character_id)
	
	if selected_character_id.is_empty():
		print("ERROR: No character selected")
		return
	
	# Set the selected character as active in the current save
	GlobalState.set_active_character(selected_character_id)
	
	# Make sure we update the save file with this character
	var save_data = GlobalState.get_active_save_data()
	print("Save data loaded: ", !save_data.is_empty())
	
	if !save_data.is_empty():
		# Update the active character ID in the save data
		save_data["active_character_id"] = selected_character_id
		print("Setting active_character_id in save to: ", selected_character_id)
		
		# Also make sure the character is in the character_ids list
		if !save_data.has("character_ids"):
			save_data["character_ids"] = []
			print("Created new character_ids array")
		
		if !save_data.character_ids.has(selected_character_id):
			save_data.character_ids.append(selected_character_id)
			print("Added character to character_ids list")
		
		# Save the changes back to the file
		var success = GlobalState.save_active_save_data(save_data)
		print("Save successful: ", success)
	else:
		print("ERROR: No active save data found")
	
	# Return to game start screen
	get_tree().change_scene_to_file("res://scenes/mainmenu/GameStart.tscn")
