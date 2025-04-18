extends Control

# Scene paths
const GAME_START_SCENE = "res://scenes/mainmenu/GameStart.tscn"
const CHARACTER_BUILD_SCENE = "res://scenes/mainmenu/charactercreator/CharacterBuild.tscn"
const RACE_SELECTION_SCENE = "res://scenes/mainmenu/charactercreator/RaceSelection.tscn"

# Node references
@onready var character_list = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/LeftPanel/CharacterListContainer/CharacterList
@onready var prev_page_button = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/LeftPanel/CharacterListContainer/PaginationContainer/PrevPageButton
@onready var next_page_button = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/LeftPanel/CharacterListContainer/PaginationContainer/NextPageButton
@onready var page_indicator = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/LeftPanel/CharacterListContainer/PaginationContainer/PageIndicator

# Character details panel
@onready var character_name_label = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterName
@onready var portrait = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterInfo/Portrait
@onready var race_value = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterInfo/InfoContainer/StatsContainer/RaceValue
@onready var age_value = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterInfo/InfoContainer/StatsContainer/AgeValue
@onready var gender_value = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterInfo/InfoContainer/StatsContainer/GenderValue
@onready var location_value = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterInfo/InfoContainer/StatsContainer/LocationValue
@onready var status_value = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/CharacterInfo/InfoContainer/StatsContainer/StatusValue

# Sprite preview
@onready var sprite_front = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/SpritePreview/Front
@onready var sprite_back = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/SpritePreview/Back
@onready var sprite_left = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/SpritePreview/Left
@onready var sprite_right = $MainContainer/ContentPanel/VBoxContainer/HBoxContainer/RightPanel/CharacterDetails/SpritePreview/Right

# Buttons
@onready var delete_button = $MainContainer/ContentPanel/VBoxContainer/ButtonPanel/DeleteButton
@onready var edit_button = $MainContainer/ContentPanel/VBoxContainer/ButtonPanel/EditButton
@onready var back_button = $MainContainer/ContentPanel/VBoxContainer/ButtonPanel/BackButton
@onready var create_button = $MainContainer/ContentPanel/VBoxContainer/ButtonPanel/CreateButton
@onready var start_button = $MainContainer/ContentPanel/VBoxContainer/ButtonPanel/StartButton

# Popups
var delete_confirmation_popup: ConfirmationDialog
var creating_character_popup: Window

# Character list data
var characters: Array = []
var current_page: int = 0
var items_per_page: int = 10
var selected_character_id: String = ""

func _ready():
	# Ensure the characters directory exists
	var dir = DirAccess.open("user://")
	if !dir.dir_exists("characters"):
		dir.make_dir("characters")
	
	# Connect button signals
	prev_page_button.pressed.connect(_on_prev_page_button_pressed)
	next_page_button.pressed.connect(_on_next_page_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)
	edit_button.pressed.connect(_on_edit_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	create_button.pressed.connect(_on_create_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	
	# Connect list signals
	character_list.item_selected.connect(_on_character_selected)
	
	# Create popups
	_create_delete_confirmation_popup()
	_create_creating_character_popup()
	
	# Load characters and update UI
	load_characters()
	update_character_list()
	update_ui_state()

# UI Creation
func _create_delete_confirmation_popup():
	delete_confirmation_popup = ConfirmationDialog.new()
	delete_confirmation_popup.title = "Confirm Deletion"
	delete_confirmation_popup.dialog_text = "Are you sure you want to delete this character? This action cannot be undone."
	delete_confirmation_popup.min_size = Vector2(400, 150)
	delete_confirmation_popup.confirmed.connect(_on_delete_confirmed)
	
	add_child(delete_confirmation_popup)

func _create_creating_character_popup():
	creating_character_popup = Window.new()
	creating_character_popup.title = "Character Creation"
	creating_character_popup.size = Vector2(300, 100)
	creating_character_popup.unresizable = true
	creating_character_popup.exclusive = true
	creating_character_popup.hide()
	
	var label = Label.new()
	label.text = "Creating character..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = SIZE_EXPAND_FILL
	
	creating_character_popup.add_child(label)
	add_child(creating_character_popup)

# Data Operations
func load_characters():
	characters.clear()
	
	var dir = DirAccess.open(GlobalVars.CHARACTERS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".json"):
				var character_id = file_name.get_basename()
				var character_data = load_character_data(character_id)
				
				if character_data.size() > 0:
					characters.append({
						"id": character_id,
						"data": character_data
					})
			
			file_name = dir.get_next()
	
	# Sort characters by name
	characters.sort_custom(func(a, b): return a.data.get("Name", "").naturalnocasecmp_to(b.data.get("Name", "")) < 0)

func load_character_data(character_id: String) -> Dictionary:
	var file_path = GlobalVars.CHARACTERS_DIR + character_id + ".json"
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			return json.data
	
	return {}

func save_character_data(character_id: String, data: Dictionary) -> bool:
	var file_path = GlobalVars.CHARACTERS_DIR + character_id + ".json"
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
	
	var json_text = JSON.stringify(data, "  ")
	file.store_string(json_text)
	file.close()
	
	return true

func delete_character(character_id: String) -> bool:
	var file_path = GlobalVars.CHARACTERS_DIR + character_id + ".json"
	
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open(GlobalVars.CHARACTERS_DIR)
		return dir.remove(character_id + ".json") == OK
	
	return false

func create_new_character() -> String:
	# Generate unique ID based on current date/time
	var character_id = ""
	var datetime = Time.get_datetime_dict_from_system()
	
	# Try creating a unique ID
	var attempts = 0
	while attempts < 100:  # Limit attempts to prevent infinite loop
		character_id = "%d%02d%02d%02d%02d%02d_%03d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute, datetime.second, 
			randi() % 1000  # Add random number to ensure uniqueness
		]
		
		var file_path = GlobalVars.CHARACTERS_DIR + character_id + ".json"
		if !FileAccess.file_exists(file_path):
			break
		
		# Wait a brief moment and try again
		await get_tree().create_timer(0.01).timeout
		datetime = Time.get_datetime_dict_from_system()
		attempts += 1
	
	# Create basic character data
	var character_data = {
		"Name": "New Character",
		"Age": 25,
		"Race": "",  # Will be selected in race selection screen
		"Gender": "Male",
		"Location": "Unassigned",
		"Status": "Alive"
	}
	
	# Save the new character
	if save_character_data(character_id, character_data):
		return character_id
	
	return ""

# UI Update
func update_character_list():
	character_list.clear()
	
	# Calculate total pages
	var total_pages = ceil(float(characters.size()) / items_per_page)
	if total_pages == 0:
		total_pages = 1
	
	# Ensure current page is within bounds
	current_page = clamp(current_page, 0, total_pages - 1)
	
	# Update pagination UI
	page_indicator.text = "Page %d/%d" % [current_page + 1, total_pages]
	prev_page_button.disabled = current_page <= 0
	next_page_button.disabled = current_page >= total_pages - 1 || total_pages <= 1
	
	# Calculate start and end indices for the current page
	var start_idx = current_page * items_per_page
	var end_idx = min(start_idx + items_per_page, characters.size())
	
	# Add characters for the current page
	for i in range(start_idx, end_idx):
		var character = characters[i]
		var display_text = character.data.get("Name", "Unnamed Character")
		
		# Add race and age if available
		var race = character.data.get("Race", "")
		var age = character.data.get("Age", "")
		if race != "" && age != null && age != 0:
			display_text += " (%s, %s)" % [race, age]
		elif race != "":
			display_text += " (%s)" % race
		
		character_list.add_item(display_text)
		character_list.set_item_metadata(character_list.item_count - 1, character.id)
		
		# Select if this is the currently selected character
		if character.id == selected_character_id:
			character_list.select(character_list.item_count - 1)

func update_character_details(character_id: String):
	if character_id.is_empty():
		# Clear details
		character_name_label.text = "Select a Character"
		race_value.text = "-"
		age_value.text = "-"
		gender_value.text = "-"
		location_value.text = "-"
		status_value.text = "-"
		
		# Clear sprites
		sprite_front.texture = null
		sprite_back.texture = null
		sprite_left.texture = null
		sprite_right.texture = null
		portrait.texture = null
		
		return
	
	# Find character data
	var character_data = {}
	for character in characters:
		if character.id == character_id:
			character_data = character.data
			break
	
	if character_data.size() > 0:
		# Update info
		character_name_label.text = character_data.get("Name", "Unnamed Character")
		race_value.text = character_data.get("Race", "-")
		age_value.text = str(character_data.get("Age", "-"))
		gender_value.text = character_data.get("Gender", "-")
		location_value.text = character_data.get("Location", "-")
		status_value.text = character_data.get("Status", "-")
		
		# TODO: Load sprites and portrait if available
		# We'll use placeholder logic for now
		var placeholder_texture = null
		
		# Debugging info to see if we have a portrait
		var portrait_path = character_data.get("PortraitPath", "")
		if !portrait_path.is_empty() && FileAccess.file_exists(portrait_path):
			# Load portrait if exists
			var portrait_texture = load(portrait_path)
			if portrait_texture:
				portrait.texture = portrait_texture
		else:
			portrait.texture = placeholder_texture
			
		sprite_front.texture = placeholder_texture
		sprite_back.texture = placeholder_texture
		sprite_left.texture = placeholder_texture
		sprite_right.texture = placeholder_texture

func update_ui_state():
	var has_selection = !selected_character_id.is_empty()
	
	delete_button.disabled = !has_selection
	edit_button.disabled = !has_selection
	start_button.disabled = !has_selection
	
	# Update character details panel
	update_character_details(selected_character_id)

# Button Handlers
func _on_prev_page_button_pressed():
	if current_page > 0:
		current_page -= 1
		update_character_list()

func _on_next_page_button_pressed():
	var total_pages = ceil(float(characters.size()) / items_per_page)
	if current_page < total_pages - 1:
		current_page += 1
		update_character_list()

func _on_character_selected(index: int):
	selected_character_id = character_list.get_item_metadata(index)
	GlobalVars.selected_character_id = selected_character_id
	update_ui_state()

func _on_delete_button_pressed():
	if !selected_character_id.is_empty():
		delete_confirmation_popup.popup_centered()

func _on_delete_confirmed():
	if delete_character(selected_character_id):
		# Refresh the list
		selected_character_id = ""
		load_characters()
		update_character_list()
		update_ui_state()

func _on_edit_button_pressed():
	if !selected_character_id.is_empty():
		# Set edit mode flag
		GlobalVars.edit_character_mode = true
		
		# Store character ID in global vars
		GlobalVars.selected_character_id = selected_character_id
		
		# Store character ID in global vars as currently selected character
		# We'll use the save data for this
		if !GlobalVars.selected_save.is_empty():
			GlobalVars.selected_save_data["CurrentCharacter"] = selected_character_id
		
		# Go to character build scene
		get_tree().change_scene_to_file(CHARACTER_BUILD_SCENE)

func _on_back_button_pressed():
	get_tree().change_scene_to_file(GAME_START_SCENE)

func _on_create_button_pressed():
	# Show creating character popup
	creating_character_popup.popup_centered()
	
	# Create new character file
	var character_id = await create_new_character()
	
	if !character_id.is_empty():
		# Update selected character
		selected_character_id = character_id
		GlobalVars.selected_character_id = character_id
		
		# Store character ID in global vars
		if !GlobalVars.selected_save.is_empty():
			GlobalVars.selected_save_data["CurrentCharacter"] = character_id
		
		# Close popup
		creating_character_popup.hide()
		
		# Go to race selection
		get_tree().change_scene_to_file(RACE_SELECTION_SCENE)
	else:
		# Failed to create character
		creating_character_popup.hide()
		
		# Show error message
		var error_dialog = AcceptDialog.new()
		error_dialog.title = "Error"
		error_dialog.dialog_text = "Failed to create new character."
		add_child(error_dialog)
		error_dialog.popup_centered()

func _on_start_button_pressed():
	if !selected_character_id.is_empty() && !GlobalVars.selected_save.is_empty():
		# Update save file with selected character
		GlobalVars.selected_save_data["CurrentCharacter"] = selected_character_id
		# Also update global character selection
		GlobalVars.selected_character_id = ""
		
		# Save the changes
		var file_path = GlobalVars.SAVES_DIR + GlobalVars.selected_save
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			var json_text = JSON.stringify(GlobalVars.selected_save_data, "  ")
			file.store_string(json_text)
			file.close()
		
		# Go back to game start
		get_tree().change_scene_to_file(GAME_START_SCENE)
