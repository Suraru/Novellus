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
var selected_file_path := ""

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
	selected_file_path = ""
	_reset_ui_state()

	var dir = DirAccess.open("res://characters")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var found = false
		
		while file_name != "":
			if file_name.ends_with(".json"):
				var file_path = "res://characters/" + file_name
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var json_text = file.get_as_text()
					var json = JSON.parse_string(json_text)
					if typeof(json) == TYPE_DICTIONARY:
						found = true
						characters.append({
							"data": json,
							"file": file_path
						})
			file_name = dir.get_next()
		dir.list_dir_end()

		if not found:
			character_list.add_item("You have no saved characters! Create one to begin.")
			character_list.set_item_disabled(0, true)
			_reset_character_info()
		else:
			# Sort characters alphabetically by name
			characters.sort_custom(func(a, b): return a.data.get("fullname", "") < b.data.get("fullname", ""))
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
		selected_file_path = characters[actual_index].file
		edit_button.disabled = false
		delete_button.disabled = false
		start_button.disabled = false
		GlobalState.current_character_path = selected_file_path
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
	if selected_file_path != "":
		GlobalState.current_character_path = selected_file_path
		GlobalState.is_editing_character = true
		get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/ChangeAppearance.tscn")

func _on_delete_pressed():
	if selected_file_path != "":
		var dir := DirAccess.open("res://")
		if dir and FileAccess.file_exists(selected_file_path):
			dir.remove(selected_file_path)
			
			# Reload characters and reset UI
			_load_characters()
			_reset_ui_state()

func _on_create_pressed():
	var new_character = {
		"name": "New",
		"surname": "Character",
		"fullname": "New Character",
		"gender": "Male",
		"location": "The Void",
		"status": "Alive",
	}
	
	var filename = "res://characters/character_%d.json" % Time.get_unix_time_from_system()
	var file = FileAccess.open(filename, FileAccess.WRITE)
	file.store_string(JSON.stringify(new_character, "	"))
	GlobalState.current_character_path = filename
	file.close()
	
	_load_characters()
	GlobalState.is_editing_character = false
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/RaceSelection.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/GameStart.tscn")

func _on_start_pressed():
	if selected_file_path == "":
		return
	
	# Set the global character path
	GlobalState.current_character_path = selected_file_path
	
	# Check if we're coming from a save creation
	if coming_from_save_path != "":
		print("DEBUG: Updating save file: " + coming_from_save_path + " with character: " + selected_file_path)
		
		# Update the save file with the selected character
		var success = _update_save_with_character(coming_from_save_path, selected_file_path)
		
		if success:
			print("DEBUG: Successfully updated save file")
		else:
			print("DEBUG: Failed to update save file")
		
		# Clear the current_save_path in GlobalState since we're done with it
		GlobalState.current_save_path = ""
	
	# Return to the GameStart scene
	get_tree().change_scene_to_file("res://scenes/mainmenu/GameStart.tscn")

func _update_save_with_character(save_path, character_path):
	print("DEBUG: Attempting to update save file: " + save_path + " with character: " + character_path)
	
	# Make sure the save file exists
	if not FileAccess.file_exists(save_path):
		print("DEBUG: Save file does not exist at: " + save_path)
		return false
	
	# Read the save file data
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		print("DEBUG: Failed to open save file for reading")
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	# Parse the save data
	var save_data = JSON.parse_string(json_text)
	if typeof(save_data) != TYPE_DICTIONARY:
		print("DEBUG: Failed to parse save data as dictionary")
		return false
	
	print("DEBUG: Successfully parsed save data")
	
	# Update the save data
	save_data["active_character"] = character_path
	print("DEBUG: Set active_character to: " + character_path)
	
	# Add to characters list if not already there
	if not "characters" in save_data:
		save_data["characters"] = []
	
	if not character_path in save_data["characters"]:
		save_data["characters"].append(character_path)
		print("DEBUG: Added character to characters list")
	
	# Update the save name with character name if it's a new save
	if save_data["save_name"] == "New Save" and FileAccess.file_exists(character_path):
		var char_file = FileAccess.open(character_path, FileAccess.READ)
		if char_file:
			var char_json_text = char_file.get_as_text()
			char_file.close()
			
			var char_data = JSON.parse_string(char_json_text)
			if typeof(char_data) == TYPE_DICTIONARY and char_data.has("fullname"):
				save_data["save_name"] = char_data["fullname"] + "'s Game"
				print("DEBUG: Updated save name to: " + save_data["save_name"])
	
	# Write the updated data back to the file
	file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		print("DEBUG: Failed to open save file for writing")
		return false
	
	var new_json_text = JSON.stringify(save_data, "  ")
	print("DEBUG: Writing updated save data: " + new_json_text)
	file.store_string(new_json_text)
	file.close()
	
	print("DEBUG: Successfully wrote updated save file")
	return true
