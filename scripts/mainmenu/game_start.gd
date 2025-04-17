extends Control

# Paths
const SAVE_DIR = "user://saves/"
const CHARACTER_SELECTION_SCENE = "res://scenes/mainmenu/CharacterSelection.tscn"
const MAIN_MENU_SCENE = "res://scenes/mainmenu/MainMenu.tscn"

# Node references
@onready var save_type_tabs = $MainContainer/SaveFilesPanel/SaveTypeTabs
@onready var save_file_list = $MainContainer/SaveFilesPanel/SaveFileList
@onready var create_save_button = $MainContainer/SaveFilesPanel/SaveButtonsContainer/CreateSaveButton
@onready var delete_save_button = $MainContainer/SaveFilesPanel/SaveButtonsContainer/DeleteSaveButton
@onready var start_button = $MainContainer/SaveFilesPanel/StartButton
@onready var back_button = $ButtonPanel/BackButton
@onready var switch_character_button = $MainContainer/CharacterPreviewPanel/SwitchCharacterButton

# Multiplayer specific nodes
@onready var multiplayer_container = $MainContainer/SaveFilesPanel/MultiplayerContainer
@onready var server_ip_input = $MainContainer/SaveFilesPanel/MultiplayerContainer/ServerIPInput
@onready var add_server_button = $MainContainer/SaveFilesPanel/MultiplayerContainer/AddServerButton
@onready var delete_server_button = $MainContainer/SaveFilesPanel/MultiplayerContainer/DeleteServerButton

# Character preview nodes
@onready var no_character_label = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/NoCharacterLabel
@onready var character_portrait = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterPortrait
@onready var character_details = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails
@onready var character_name_label = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/NameLabel
@onready var age_value = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid/AgeValue
@onready var race_value = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid/RaceValue
@onready var gender_value = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid/GenderValue
@onready var lifestage_value = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid/LifestageValue

# Currently selected save file
var selected_save_file = ""
var selected_server = ""
var server_list = []

func _ready():
	# Create save directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	
	# Connect signals
	save_type_tabs.tab_changed.connect(_on_tab_changed)
	save_file_list.item_selected.connect(_on_save_file_selected)
	save_file_list.item_activated.connect(_on_save_file_activated)
	create_save_button.pressed.connect(_on_create_save_button_pressed)
	delete_save_button.pressed.connect(_on_delete_save_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	switch_character_button.pressed.connect(_on_switch_character_button_pressed)
	server_ip_input.text_changed.connect(_on_server_ip_input_changed)
	add_server_button.pressed.connect(_on_add_server_button_pressed)
	delete_server_button.pressed.connect(_on_delete_server_button_pressed)
	
	# Initial state setup
	_on_tab_changed(save_type_tabs.current_tab)
	_update_save_list()

func _on_tab_changed(tab_index):
	# Clear the file list
	save_file_list.clear()
	selected_save_file = ""
	selected_server = ""
	delete_save_button.disabled = true
	start_button.disabled = true
	switch_character_button.disabled = true
	
	# Reset character preview
	_hide_character_preview()
	
	match tab_index:
		0: # Saved Games
			multiplayer_container.visible = false
			create_save_button.visible = true
			delete_save_button.visible = true
			_update_save_list()
		
		1: # Campaigns
			multiplayer_container.visible = false
			create_save_button.visible = false
			delete_save_button.visible = false
			# You might want to load available campaigns here
		
		2: # Multiplayer
			multiplayer_container.visible = true
			create_save_button.visible = false
			delete_save_button.visible = false
			delete_server_button.disabled = true
			_update_server_list()

func _update_save_list():
	save_file_list.clear()
	
	# Check if directory exists
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		return
	
	# Get list of save files
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".save"):
				# Open the save file to get the save name if possible
				var file_path = SAVE_DIR + file_name
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var json_text = file.get_as_text()
					file.close()
					
					var parse_result = JSON.parse_string(json_text)
					if parse_result != null and typeof(parse_result) == TYPE_DICTIONARY and parse_result.has("save_name"):
						# Display the save_name property instead of just the filename
						save_file_list.add_item(parse_result["save_name"])
					else:
						# Fallback to filename if no save_name found
						save_file_list.add_item(file_name.get_basename())
				else:
					save_file_list.add_item(file_name.get_basename())
			
			file_name = dir.get_next()

func _update_server_list():
	save_file_list.clear()
	
	# Load server list from user settings
	_load_server_list()
	
	# Add servers to list
	for server in server_list:
		save_file_list.add_item(server)

func _load_server_list():
	# Load from a configuration file
	var config = ConfigFile.new()
	var err = config.load(SAVE_DIR + "servers.cfg")
	
	if err == OK:
		server_list = config.get_value("servers", "list", [])
	else:
		server_list = []

func _save_server_list():
	# Save to a configuration file
	var config = ConfigFile.new()
	config.set_value("servers", "list", server_list)
	config.save(SAVE_DIR + "servers.cfg")

func _on_save_file_selected(index):
	var current_tab = save_type_tabs.current_tab
	
	match current_tab:
		0: # Saved Games
			var display_name = save_file_list.get_item_text(index)
			selected_save_file = display_name
			delete_save_button.disabled = false
			start_button.disabled = false
			switch_character_button.disabled = false
			
			# Find the actual filename for this save
			var actual_filename = _find_save_file_by_name(display_name)
			if !actual_filename.is_empty():
				# Set this as the active save in GlobalState - use the actual filename
				GlobalState.set_active_save(actual_filename)
				print("Setting active save to: " + actual_filename)
				
				# Load character preview from this save
				_load_save_character_preview(actual_filename)
			else:
				print("ERROR: Could not find save file with name: " + display_name)
				_hide_character_preview()
		
		1: # Campaigns
			# Handle campaign selection
			pass
		
		2: # Multiplayer
			selected_server = save_file_list.get_item_text(index)
			delete_server_button.disabled = false
			start_button.disabled = false

func _find_save_file_by_name(save_name: String) -> String:
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".save"):
				# Check if this is the file with the matching save_name
				var file_path = SAVE_DIR + file_name
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var json_text = file.get_as_text()
					file.close()
					
					var save_data = JSON.parse_string(json_text)
					if save_data and save_data.has("save_name") and save_data.save_name == save_name:
						return file_name
			
			file_name = dir.get_next()
	
	return ""

func _on_save_file_activated(index):
	# Double-click on a save file starts the game
	_on_start_button_pressed()

func _on_create_save_button_pressed():
	# Create a new save file with timestamp
	var timestamp = Time.get_datetime_string_from_system()
	var save_name = "save_" + timestamp.replace(":", "-").replace(" ", "_")
	var save_path = SAVE_DIR + save_name + ".save"
	
	# Create an empty save file
	var save_data = {
		"save_name": "New Save",
		"created_at": timestamp,
		"last_played": timestamp,
		"character_ids": [],
		"active_character_id": ""
	}
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "  "))
		file.close()
	
	# Set as active save
	GlobalState.set_active_save(save_name)
	
	# Update the save list
	_update_save_list()
	
	# Navigate to character creation
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/CharacterSelection.tscn")

func _on_delete_save_button_pressed():
	if selected_save_file.is_empty():
		return
	
	# Confirm deletion
	var confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.title = "Confirm Deletion"
	confirmation_dialog.dialog_text = "Are you sure you want to delete " + selected_save_file + "?"
	confirmation_dialog.confirmed.connect(func():
		# Need to find the actual filename since we're displaying save_name
		var actual_filename = ""
		var dir = DirAccess.open(SAVE_DIR)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			
			while file_name != "":
				if file_name.ends_with(".save"):
					# Check if this is the file with the matching save_name
					var file_path = SAVE_DIR + file_name
					var file = FileAccess.open(file_path, FileAccess.READ)
					if file:
						var json_text = file.get_as_text()
						file.close()
						
						var save_data = JSON.parse_string(json_text)
						if save_data and save_data.has("save_name") and save_data.save_name == selected_save_file:
							actual_filename = file_name
							break
				
				file_name = dir.get_next()
			
			if actual_filename != "":
				dir.remove(actual_filename)
				print("Deleted save file: " + actual_filename)
				_update_save_list()
				selected_save_file = ""
				delete_save_button.disabled = true
				start_button.disabled = true
				switch_character_button.disabled = true
				_hide_character_preview()
			else:
				print("ERROR: Could not find save file with name: " + selected_save_file)
		)
	
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()

func _on_start_button_pressed():
	if selected_save_file.is_empty() and selected_server.is_empty():
		return
	
	var current_tab = save_type_tabs.current_tab
	
	match current_tab:
		0: # Saved Games
			# Load the saved game
			var save_path = SAVE_DIR + selected_save_file + ".save"
			if FileAccess.file_exists(save_path):
				# You would typically load the game state here
				# For now, we'll just print a message
				print("Starting game with save file: " + selected_save_file)
				# Get the game scene path from the save file and load it
				# get_tree().change_scene_to_file(game_scene_path)
		
		1: # Campaigns
			# Start the selected campaign
			pass
		
		2: # Multiplayer
			# Connect to the selected server
			print("Connecting to server: " + selected_server)
			# You would add networking code here to connect to the server

func _on_back_button_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/mainmenu/MainMenu.tscn")

func _on_switch_character_button_pressed():
	if selected_save_file.is_empty():
		return
	
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/CharacterSelection.tscn")

func _on_server_ip_input_changed(new_text):
	# Basic IP:Port validation
	var ip_pattern = "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}:[0-9]{1,5}$"
	var regex = RegEx.new()
	regex.compile(ip_pattern)
	
	add_server_button.disabled = !regex.search(new_text)

func _on_add_server_button_pressed():
	var server_address = server_ip_input.text
	
	if server_address.is_empty() or server_list.has(server_address):
		return
	
	server_list.append(server_address)
	_save_server_list()
	_update_server_list()
	server_ip_input.clear()
	add_server_button.disabled = true

func _on_delete_server_button_pressed():
	if selected_server.is_empty():
		return
	
	# Confirm deletion
	var confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.title = "Confirm Server Removal"
	confirmation_dialog.dialog_text = "Are you sure you want to remove server " + selected_server + "?"
	confirmation_dialog.confirmed.connect(func():
		server_list.erase(selected_server)
		_save_server_list()
		_update_server_list()
		selected_server = ""
		delete_server_button.disabled = true
		start_button.disabled = true
	)
	
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()

func _load_character_preview(save_name):
	var save_path = SAVE_DIR + save_name + ".save"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var save_data = file.get_var()
			file.close()
			
			if save_data and save_data.has("characters") and save_data.characters.size() > 0:
				var character = save_data.characters[0]  # Display the first character
				
				# Show character details
				no_character_label.visible = false
				character_portrait.visible = true
				character_details.visible = true
				
				# Set character information
				if character.has("name"):
					character_name_label.text = character.name
				if character.has("age"):
					age_value.text = str(character.age)
				if character.has("race"):
					race_value.text = character.race
				if character.has("gender"):
					gender_value.text = character.gender
				if character.has("lifestage"):
					lifestage_value.text = character.lifestage
				
				# Load portrait if available
				if character.has("portrait") and character.portrait != "":
					var texture = load(character.portrait)
					if texture:
						character_portrait.texture = texture
			else:
				_hide_character_preview()
	else:
		_hide_character_preview()

func _load_save_character_preview(save_filename):
	var save_path = SAVE_DIR + save_filename
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			
			var save_data = JSON.parse_string(json_text)
			if save_data and save_data.has("active_character_id") and !save_data.active_character_id.is_empty():
				var character_id = save_data.active_character_id
				var character_data = GlobalState.load_character_data(character_id)
				
				if !character_data.is_empty():
					# Show character details
					no_character_label.visible = false
					character_portrait.visible = true
					character_details.visible = true
					
					# Set character information
					if character_data.has("fullname"):
						character_name_label.text = character_data.fullname
					else:
						character_name_label.text = character_data.get("name", "") + " " + character_data.get("surname", "")
					
					age_value.text = str(character_data.get("age", "-"))
					race_value.text = character_data.get("race", "-")
					gender_value.text = character_data.get("gender", "-")
					lifestage_value.text = character_data.get("lifestage", "-")
					
					return
			
			# If we get here, there's no valid character
			_hide_character_preview()

func _hide_character_preview():
	no_character_label.visible = true
	character_portrait.visible = false
	character_details.visible = false
