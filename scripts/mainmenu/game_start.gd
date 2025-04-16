extends Control

@onready var background = $Characterbg
@onready var save_file_list = $MainContainer/SaveFilesPanel/SaveFileList
@onready var switch_character_button = $MainContainer/CharacterPreviewPanel/SwitchCharacterButton
@onready var no_character_label = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/NoCharacterLabel
@onready var character_portrait = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterPortrait
@onready var character_details = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails
@onready var name_label = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/NameLabel
@onready var age_value = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid/AgeValue
@onready var race_value = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid/RaceValue
@onready var gender_value = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid/GenderValue
@onready var lifestage_value = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid/LifestageValue
@onready var start_button = $MainContainer/SaveFilesPanel/StartButton
@onready var back_button = $ButtonPanel/BackButton
@onready var save_type_tabs = $MainContainer/SaveFilesPanel/SaveTypeTabs

# References to new UI elements we need to add
@onready var create_save_button = $MainContainer/SaveFilesPanel/SaveButtonsContainer/CreateSaveButton
@onready var delete_save_button = $MainContainer/SaveFilesPanel/SaveButtonsContainer/DeleteSaveButton
@onready var server_ip_input = $MainContainer/SaveFilesPanel/MultiplayerContainer/ServerIPInput
@onready var add_server_button = $MainContainer/SaveFilesPanel/MultiplayerContainer/AddServerButton
@onready var delete_server_button = $MainContainer/SaveFilesPanel/MultiplayerContainer/DeleteServerButton

# Enum for file types to improve code readability
enum FileType { CAMPAIGN, SAVE_FILE, SERVER }

# Structured save data to better organize information
class SaveData:
	var file_path: String
	var data: Dictionary
	var type: int  # Using the FileType enum
	
	func _init(p_path: String, p_data: Dictionary, p_type: int):
		file_path = p_path
		data = p_data
		type = p_type

var save_files = []
var selected_file_path := ""
var current_character_path := ""  # Track which character is active in the save
var newly_created_save_path := ""  # Track newly created save path

# Add confirmation dialog for delete operations
var confirm_dialog: ConfirmationDialog

func _ready():
	# Create confirmation dialog for delete operations
	_create_confirm_dialog()
	
	# Connect signals for existing UI elements
	if save_file_list:
		save_file_list.item_selected.connect(_on_save_selected)
	else:
		push_error("SaveFileList not found in GameStart scene")
	
	if switch_character_button:
		switch_character_button.pressed.connect(_on_choose_character_pressed)
		switch_character_button.disabled = true  # Initially disabled
	else:
		push_error("SwitchCharacterButton not found in GameStart scene")
	
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	else:
		push_error("StartButton not found in GameStart scene")
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	else:
		push_error("BackButton not found in GameStart scene")
	
	# Connect tab changed signal if tabs exist
	if save_type_tabs:
		save_type_tabs.tab_changed.connect(_on_tab_changed)
	else:
		push_warning("SaveTypeTabs not found, defaulting to save files only")
	
	# Connect signals for new UI elements
	_connect_new_ui_signals()
	
	# Make sure background is appropriately sized
	_on_viewport_size_changed()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Check if we're returning from character selection with a newly created save
	_check_returning_from_character_selection()
	
	# Load save files for the current tab
	_load_files()

func _create_confirm_dialog():
	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Are you sure you want to delete this item?"
	confirm_dialog.get_ok_button().text = "Yes"
	confirm_dialog.get_cancel_button().text = "No"
	add_child(confirm_dialog)

func _connect_new_ui_signals():
	# Connect signals for the save file buttons
	if create_save_button:
		create_save_button.pressed.connect(_on_create_save_pressed)
	
	if delete_save_button:
		delete_save_button.pressed.connect(_on_delete_save_pressed)
	
	# Connect signals for server management
	if add_server_button:
		add_server_button.pressed.connect(_on_add_server_pressed)
	
	if delete_server_button:
		delete_server_button.pressed.connect(_on_delete_server_pressed)
	
	if server_ip_input:
		server_ip_input.text_changed.connect(_on_server_ip_changed)
		# Initialize add server button as disabled
		if add_server_button:
			add_server_button.disabled = true

func _check_returning_from_character_selection():
	# Check if we're returning from character selection with a newly created save
	if Engine.has_singleton("GlobalState"):
		if GlobalState.has_method("get") and GlobalState.get("temp_save_path") != null:
			var temp_save_path = GlobalState.get("temp_save_path")
			var new_char_path = GlobalState.get("new_character_path")
			
			# Clear the temporary values
			GlobalState.temp_save_path = null
			GlobalState.new_character_path = null
			
			# If we have both a save path and a character path, update the save file
			if temp_save_path != "" and new_char_path != "" and FileAccess.file_exists(temp_save_path):
				_update_save_with_character(temp_save_path, new_char_path)
				
				# Store the save path to select it in the list
				newly_created_save_path = temp_save_path

func _update_save_with_character(save_path, character_path):
	# Update the save file with the new character
	if FileAccess.file_exists(save_path) and FileAccess.file_exists(character_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			var save_data = JSON.parse_string(json_text)
			if typeof(save_data) == TYPE_DICTIONARY:
				# Update the active character
				save_data["active_character"] = character_path
				
				# Add the character to the list if not already present
				if not "characters" in save_data:
					save_data["characters"] = []
				
				if not character_path in save_data["characters"]:
					save_data["characters"].append(character_path)
				
				# Update the save name with character name if it's a new save
				if save_data["save_name"] == "New Save" and FileAccess.file_exists(character_path):
					var char_file = FileAccess.open(character_path, FileAccess.READ)
					if char_file:
						var char_json_text = char_file.get_as_text()
						var char_data = JSON.parse_string(char_json_text)
						if typeof(char_data) == TYPE_DICTIONARY and char_data.has("fullname"):
							save_data["save_name"] = char_data["fullname"] + "'s Game"
				
				# Write the updated data back to the file
				file = FileAccess.open(save_path, FileAccess.WRITE)
				if file:
					json_text = JSON.stringify(save_data, "  ")
					file.store_string(json_text)
					file.close()

func _on_viewport_size_changed():
	# Ensure background scales with the window
	var background = get_node_or_null("Characterbg")
	if not background or not background.texture:
		return
		
	var viewport_size = get_viewport().get_visible_rect().size
	var bg_texture_size = background.texture.get_size()
	var bg_scale_x = viewport_size.x / bg_texture_size.x
	var bg_scale_y = viewport_size.y / bg_texture_size.y
	var scaling_factor = max(bg_scale_x, bg_scale_y)
	
	background.scale = Vector2(scaling_factor, scaling_factor)

func _load_files():
	if not save_file_list:
		return
		
	save_file_list.clear()
	save_files.clear()
	selected_file_path = ""
	if start_button:
		start_button.disabled = true
	
	var current_tab = 0
	if save_type_tabs:
		current_tab = save_type_tabs.current_tab
	
	# Update UI based on current tab
	_update_ui_for_tab(current_tab)
	
	# Load files based on the current tab
	match current_tab:
		0:  # Saved Games
			_load_save_game_files()
		1:  # Campaigns
			_load_campaign_files()
		2:  # Multiplayer
			_load_server_files()
	
	# Handle empty list
	if save_files.size() == 0:
		var message = ""
		match current_tab:
			0: message = "No saved games found."
			1: message = "No campaigns available yet."
			2: message = "No saved servers. Add a server below."
		
		save_file_list.add_item(message)
		save_file_list.set_item_disabled(0, true)
		save_file_list.select(0)
	else:
		# If we have a newly created save path, select it
		if newly_created_save_path != "":
			for i in range(save_files.size()):
				if save_files[i].file_path == newly_created_save_path:
					save_file_list.select(i)
					_on_save_selected(i)
					newly_created_save_path = ""
					break

func _update_ui_for_tab(tab_index):
	# Hide all tab-specific UI elements first
	if create_save_button and delete_save_button:
		create_save_button.visible = false
		delete_save_button.visible = false
	
	if server_ip_input and add_server_button and delete_server_button:
		server_ip_input.visible = false
		add_server_button.visible = false
		delete_server_button.visible = false
	
	# Disable switch character button by default
	if switch_character_button:
		switch_character_button.disabled = true
	
	# Update UI based on the current tab
	match tab_index:
		0:  # Saved Games
			if create_save_button and delete_save_button:
				create_save_button.visible = true
				delete_save_button.visible = true
				delete_save_button.disabled = true
		1:  # Campaigns
			# No specific UI for campaigns yet
			pass
		2:  # Multiplayer
			if server_ip_input and add_server_button and delete_server_button:
				server_ip_input.visible = true
				add_server_button.visible = true
				delete_server_button.visible = true
				delete_server_button.disabled = true

func _load_save_game_files():
	# Load save files from the saves directory
	var dir_path = "user://saves"
	
	# Check if saves directory exists
	if not DirAccess.dir_exists_absolute(dir_path):
		print("Saves directory does not exist yet. Creating directory.")
		var dir = DirAccess.open("user://")
		if dir:
			dir.make_dir("saves")
		else:
			push_error("Failed to create saves directory")
			return
	
	var dir = DirAccess.open(dir_path)
	if not dir:
		push_error("Failed to open saves directory: " + dir_path)
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var found = false
	
	while file_name != "":
		if file_name.ends_with(".save"):
			var file_path = dir_path + "/" + file_name
			if FileAccess.file_exists(file_path):
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var json_text = file.get_as_text()
					var json = JSON.parse_string(json_text)
					if typeof(json) == TYPE_DICTIONARY:
						found = true
						var save_data = SaveData.new(
							file_path,
							json,
							FileType.SAVE_FILE
						)
						save_files.append(save_data)
						
						# Get character name for display if available
						var character_name = "No Character"
						if json.has("active_character") and json["active_character"] != "":
							var char_data = _load_character_data(json["active_character"])
							if char_data and char_data.has("fullname"):
								character_name = char_data["fullname"]
						
						var label = "%s | Character: %s | Last played: %s" % [
							json.get("save_name", "Unnamed Save"),
							character_name,
							json.get("last_played_date", "Unknown")
						]
						save_file_list.add_item(label)
		
		file_name = dir.get_next()
	dir.list_dir_end()

func _load_campaign_files():
	# This function would load campaign files from a designated directory
	var dir_path = "res://campaigns"
	
	# Check if campaigns directory exists
	if not DirAccess.dir_exists_absolute(dir_path):
		print("Campaigns directory does not exist yet. No campaigns to load.")
		return
	
	var dir = DirAccess.open(dir_path)
	if not dir:
		print("Failed to open campaigns directory: ", dir_path)
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var found = false
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var file_path = dir_path + "/" + file_name
			if FileAccess.file_exists(file_path):
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var json_text = file.get_as_text()
					var json = JSON.parse_string(json_text)
					if typeof(json) == TYPE_DICTIONARY:
						found = true
						var campaign_data = SaveData.new(
							file_path,
							json,
							FileType.CAMPAIGN
						)
						save_files.append(campaign_data)
						
						var label = "%s | Difficulty: %s" % [
							json.get("name", "Unknown Campaign"),
							json.get("difficulty", "Normal")
						]
						save_file_list.add_item(label)
		
		file_name = dir.get_next()
	dir.list_dir_end()

func _load_server_files():
	# Load server files from the servers directory
	var dir_path = "user://servers"
	
	# Check if servers directory exists
	if not DirAccess.dir_exists_absolute(dir_path):
		print("Servers directory does not exist yet. Creating directory.")
		var dir = DirAccess.open("user://")
		if dir:
			dir.make_dir("servers")
		else:
			push_error("Failed to create servers directory")
			return
	
	var dir = DirAccess.open(dir_path)
	if not dir:
		push_error("Failed to open servers directory: " + dir_path)
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var found = false
	
	while file_name != "":
		if file_name.ends_with(".server"):
			var file_path = dir_path + "/" + file_name
			if FileAccess.file_exists(file_path):
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var json_text = file.get_as_text()
					var json = JSON.parse_string(json_text)
					if typeof(json) == TYPE_DICTIONARY:
						found = true
						var server_data = SaveData.new(
							file_path,
							json,
							FileType.SERVER
						)
						save_files.append(server_data)
						
						# Get character name for display if available
						var character_name = "No Character"
						if json.has("active_character") and json["active_character"] != "":
							var char_data = _load_character_data(json["active_character"])
							if char_data and char_data.has("fullname"):
								character_name = char_data["fullname"]
						
						var label = "%s | Character: %s | IP: %s" % [
							json.get("server_name", "Cannot Reach Server"),
							character_name,
							json.get("server_ip", "Unknown")
						]
						save_file_list.add_item(label)
		
		file_name = dir.get_next()
	dir.list_dir_end()

func _on_tab_changed(tab_idx):
	# Reload files when tab changes
	_load_files()

func _on_save_selected(index):
	if not save_file_list or not save_files or index < 0 or index >= save_files.size() or save_file_list.is_item_disabled(index):
		_clear_preview()
		return
	
	var selected_save = save_files[index]
	selected_file_path = selected_save.file_path
	
	# Enable delete button based on file type
	var current_tab = 0
	if save_type_tabs:
		current_tab = save_type_tabs.current_tab
	
	match current_tab:
		0:  # Saved Games
			if delete_save_button:
				delete_save_button.disabled = false
			
			# Enable switch character button only for save files
			if switch_character_button:
				switch_character_button.disabled = false
		1:  # Campaigns
			# No delete functionality for campaigns yet
			if switch_character_button:
				switch_character_button.disabled = true
		2:  # Multiplayer
			if delete_server_button:
				delete_server_button.disabled = false
			
			# Disable switch character for multiplayer servers
			if switch_character_button:
				switch_character_button.disabled = true
	
	# Update preview based on file type
	match selected_save.type:
		FileType.CAMPAIGN:
			_show_campaign_preview(selected_save.data)
		FileType.SAVE_FILE:
			_show_save_preview(selected_save.data)
		FileType.SERVER:
			_show_server_preview(selected_save.data)
	
	# Enable start button
	if start_button:
		start_button.disabled = false
	
	if Engine.has_singleton("GlobalState"):
		if selected_save.type == FileType.SAVE_FILE:
			GlobalState.current_save_path = selected_file_path
			# Set the active character from the save file
			if selected_save.data.has("active_character"):
				current_character_path = selected_save.data["active_character"]
				GlobalState.current_character_path = current_character_path
		elif selected_save.type == FileType.SERVER:
			GlobalState.current_server_path = selected_file_path
			if selected_save.data.has("active_character"):
				current_character_path = selected_save.data["active_character"]
				GlobalState.current_character_path = current_character_path

func _show_campaign_preview(campaign_data):
	# Update UI for campaign preview - check for null references
	if no_character_label:
		no_character_label.visible = false
	
	if character_details:
		character_details.visible = true
	
	if character_portrait:
		character_portrait.visible = false
	
	# Set campaign details
	if name_label:
		name_label.text = campaign_data.get("name", "Unknown Campaign")
	
	if age_value:
		age_value.text = "N/A"
	
	if race_value:
		race_value.text = "N/A"
	
	if gender_value:
		gender_value.text = "N/A"
	
	if lifestage_value:
		lifestage_value.text = campaign_data.get("difficulty", "Normal")

func _show_save_preview(save_data):
	# Get the active character from the save file
	var active_character_path = save_data.get("active_character", "")
	current_character_path = active_character_path
	
	if active_character_path == "" or not FileAccess.file_exists(active_character_path):
		# No active character or character file doesn't exist
		if no_character_label:
			no_character_label.visible = true
		
		if character_details:
			character_details.visible = false
		
		if character_portrait:
			character_portrait.visible = false
			
		return
	
	# Load the character data
	var character_data = _load_character_data(active_character_path)
	if not character_data:
		return
	
	# Update UI elements with character data
	if no_character_label:
		no_character_label.visible = false
	
	if character_details:
		character_details.visible = true
	
	# Show portrait if available
	if character_portrait:
		if character_data.has("portrait_path") and FileAccess.file_exists(character_data["portrait_path"]):
			character_portrait.texture = load(character_data["portrait_path"])
			character_portrait.visible = true
		else:
			character_portrait.visible = false
	
	# Update character details
	if name_label:
		name_label.text = character_data.get("fullname", "Unknown")
	
	if age_value:
		age_value.text = str(character_data.get("age", "??"))
	
	if race_value:
		race_value.text = character_data.get("race", "Unknown")
	
	if gender_value:
		gender_value.text = character_data.get("gender", "Unknown")
	
	# Calculate lifestage
	if lifestage_value:
		var race = character_data.get("race", "Human")
		var age = int(character_data.get("age", 25))
		var lifestage = "Adult"  # Default
		
		# Check if GlobalFormulas class exists
		if ClassDB.class_exists("GlobalFormulas") or ("GlobalFormulas" in get_script().get_script_constant_map()):
			lifestage = GlobalFormulas.get_lifestage(race, age)
		
		lifestage_value.text = lifestage

func _show_server_preview(server_data):
	# Update UI for server preview - check for null references
	if no_character_label:
		no_character_label.visible = false
	
	if character_details:
		character_details.visible = true
	
	if character_portrait:
		character_portrait.visible = false
	
	# Set server details
	if name_label:
		name_label.text = server_data.get("server_name", "Cannot Reach Server")
	
	# Show active character info if available
	var active_character_path = server_data.get("active_character", "")
	current_character_path = active_character_path
	
	if active_character_path != "" and FileAccess.file_exists(active_character_path):
		var character_data = _load_character_data(active_character_path)
		if character_data:
			if age_value:
				age_value.text = str(character_data.get("age", "??"))
			
			if race_value:
				race_value.text = character_data.get("race", "Unknown")
			
			if gender_value:
				gender_value.text = character_data.get("gender", "Unknown")
			
			if lifestage_value:
				var race = character_data.get("race", "Human")
				var age = int(character_data.get("age", 25))
				var lifestage = "Adult"  # Default
				
				# Check if GlobalFormulas class exists
				if ClassDB.class_exists("GlobalFormulas") or ("GlobalFormulas" in get_script().get_script_constant_map()):
					lifestage = GlobalFormulas.get_lifestage(race, age)
				
				lifestage_value.text = lifestage
		
		# Show character portrait if available
		if character_portrait and character_data:
			if character_data.has("portrait_path") and FileAccess.file_exists(character_data["portrait_path"]):
				character_portrait.texture = load(character_data["portrait_path"])
				character_portrait.visible = true
	else:
		# No character selected or character file doesn't exist
		if age_value:
			age_value.text = "N/A"
		
		if race_value:
			race_value.text = "N/A"
		
		if gender_value:
			gender_value.text = "N/A"
		
		if lifestage_value:
			lifestage_value.text = "N/A"

func _load_character_data(character_path):
	if not FileAccess.file_exists(character_path):
		return null
	
	var file = FileAccess.open(character_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json = JSON.parse_string(json_text)
		if typeof(json) == TYPE_DICTIONARY:
			return json
	
	return null

func _clear_preview():
	# Check for null references before setting visibility
	if no_character_label:
		no_character_label.visible = true
	
	if character_portrait:
		character_portrait.visible = false
	
	if character_details:
		character_details.visible = false
	
	if start_button:
		start_button.disabled = true
	
	selected_file_path = ""
	current_character_path = ""
	
	# Disable delete buttons
	if delete_save_button:
		delete_save_button.disabled = true
	
	if delete_server_button:
		delete_server_button.disabled = true
	
	# Disable switch character button
	if switch_character_button:
		switch_character_button.disabled = true

func _on_choose_character_pressed():
	# Store the current save path for reference
	if Engine.has_singleton("GlobalState") and selected_file_path != "":
		GlobalState.current_save_path = selected_file_path
		print("DEBUG: Setting current_save_path for character switch: " + selected_file_path)
	
	# Go to character selection screen
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/CharacterSelection.tscn")

func _on_create_save_pressed():
	# Create a new save file with default values
	var default_save_data = {
		"save_name": "New Save",
		"creation_date": Time.get_datetime_string_from_system(),
		"last_played_date": Time.get_datetime_string_from_system(),
		"active_character": "",
		"characters": [],  # List of character file paths in this save
		"world_data": {}   # Additional world state data
	}
	
	# Find or create a unique filename
	var save_dir = "user://saves"
	var base_name = "save"
	var file_ext = ".save"
	var index = 1
	var file_path = save_dir + "/" + base_name + str(index) + file_ext
	
	while FileAccess.file_exists(file_path):
		index += 1
		file_path = save_dir + "/" + base_name + str(index) + file_ext
	
	# Save the file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(default_save_data, "  ")
		file.store_string(json_text)
		file.close()
		
		# Store the save path for character creation
		if Engine.has_singleton("GlobalState"):
			# Set the current_save_path variable
			GlobalState.current_save_path = file_path
			print("DEBUG: Setting current_save_path: " + file_path)
		
		# Go to character selection screen
		get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/CharacterSelection.tscn")
	else:
		push_error("Failed to create new save file at: " + file_path)

func _on_delete_save_pressed():
	if selected_file_path == "":
		return
	
	# Confirm before deleting
	confirm_dialog.dialog_text = "Are you sure you want to delete this save?"
	confirm_dialog.confirmed.connect(_confirm_delete_save)
	confirm_dialog.popup_centered()

func _confirm_delete_save():
	# Disconnect the signal to prevent multiple connections
	confirm_dialog.confirmed.disconnect(_confirm_delete_save)
	
	# Delete the selected save file
	if selected_file_path != "" and FileAccess.file_exists(selected_file_path):
		var dir = DirAccess.open("user://")
		if dir.remove_absolute(selected_file_path) == OK:
			# Reload the save files list
			_load_files()
		else:
			push_error("Failed to delete save file: " + selected_file_path)

func _on_server_ip_changed(new_text):
	# Enable/disable add server button based on valid IP:port format
	if add_server_button:
		# Basic validation for IP:port format
		var is_valid = _validate_ip_port(new_text)
		add_server_button.disabled = not is_valid

func _validate_ip_port(ip_text):
	# Basic validation for IP:port format (can be expanded for more thorough validation)
	if ip_text.is_empty():
		return false
	
	# Check for IP:port format
	var parts = ip_text.split(":")
	if parts.size() != 2:
		return false
	
	# Basic IP validation
	var ip_parts = parts[0].split(".")
	if ip_parts.size() != 4:
		return false
	
	# Port validation
	var port = parts[1].to_int()
	if port < 1 or port > 65535:
		return false
	
	return true

func _on_add_server_pressed():
	if not server_ip_input or server_ip_input.text.is_empty():
		return
	
	var server_ip = server_ip_input.text
	
	# Create a new server entry
	var server_data = {
		"server_ip": server_ip,
		"server_name": "Cannot Reach Server",  # Default name until connection is established
		"active_character": "",  # No character selected initially
		"last_connected": Time.get_datetime_string_from_system()
	}
	
	# TODO: Actually try to connect to the server to get its name
	# For a real implementation, you would set up a connection here
	# and update the server name based on the response
	
	# Create a unique filename for the server
	var server_dir = "user://servers"
	var base_name = "server"
	var file_ext = ".server"
	var index = 1
	var file_path = server_dir + "/" + base_name + str(index) + file_ext
	
	while FileAccess.file_exists(file_path):
		index += 1
		file_path = server_dir + "/" + base_name + str(index) + file_ext
	
	# Save the server file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(server_data, "  ")
		file.store_string(json_text)
		file.close()
		
		# Clear the input field
		server_ip_input.text = ""
		
		# Reload the server files list
		_load_files()
	else:
		push_error("Failed to create new server file at: " + file_path)

func _on_delete_server_pressed():
	if selected_file_path == "":
		return
	
	# Confirm before deleting
	confirm_dialog.dialog_text = "Are you sure you want to delete this server?"
	confirm_dialog.confirmed.connect(_confirm_delete_server)
	confirm_dialog.popup_centered()

func _confirm_delete_server():
	# Disconnect the signal to prevent multiple connections
	confirm_dialog.confirmed.disconnect(_confirm_delete_server)
	
	# Delete the selected server file
	if selected_file_path != "" and FileAccess.file_exists(selected_file_path):
		var dir = DirAccess.open("user://")
		if dir.remove_absolute(selected_file_path) == OK:
			# Reload the server files list
			_load_files()
		else:
			push_error("Failed to delete server file: " + selected_file_path)

func _on_start_pressed():
	if selected_file_path == "":
		return
	
	# Find the selected save
	if not save_file_list:
		return
	
	var selected_indices = save_file_list.get_selected_items()
	if selected_indices.size() == 0:
		return
	
	var selected_index = selected_indices[0]
	if selected_index < 0 or selected_index >= save_files.size():
		return
	
	var selected_save = save_files[selected_index]
	
	match selected_save.type:
		FileType.CAMPAIGN:
			# Load campaign scene
			print("Starting campaign: " + selected_file_path)
			# Store campaign path in GlobalState if it exists
			if Engine.has_singleton("GlobalState"):
				if not "current_campaign_path" in GlobalState:
					GlobalState.set("current_campaign_path", selected_file_path)
				else:
					GlobalState.current_campaign_path = selected_file_path
			
			# Check if CampaignWorld.tscn exists
			if FileAccess.file_exists("res://scenes/CampaignWorld.tscn"):
				get_tree().change_scene_to_file("res://scenes/CampaignWorld.tscn")
			else:
				push_error("CampaignWorld.tscn not found. Falling back to SandboxWorld.tscn")
				get_tree().change_scene_to_file("res://scenes/SandboxWorld.tscn")
		
		FileType.SAVE_FILE:
			# Update last played date
			_update_last_played_date(selected_file_path)
			
			# Load sandbox mode with save
			print("Starting sandbox with save: " + selected_file_path)
			if Engine.has_singleton("GlobalState"):
				GlobalState.current_save_path = selected_file_path
				
				# Set the active character from the save file
				if selected_save.data.has("active_character"):
					GlobalState.current_character_path = selected_save.data["active_character"]
			
			get_tree().change_scene_to_file("res://scenes/SandboxWorld.tscn")
		
		FileType.SERVER:
			# Update last connected date
			_update_last_connected_date(selected_file_path)
			
			# Connect to the server
			print("Connecting to server: " + selected_file_path)
			if Engine.has_singleton("GlobalState"):
				GlobalState.current_server_path = selected_file_path
				
				# Set the active character from the server file
				if selected_save.data.has("active_character"):
					GlobalState.current_character_path = selected_save.data["active_character"]
			
			# TODO: Implement proper server connection handling
			# For now, just load the multiplayer scene
			if FileAccess.file_exists("res://scenes/MultiplayerGame.tscn"):
				get_tree().change_scene_to_file("res://scenes/MultiplayerGame.tscn")
			else:
				push_error("MultiplayerGame.tscn not found. Falling back to SandboxWorld.tscn")
				get_tree().change_scene_to_file("res://scenes/SandboxWorld.tscn")

func _update_last_played_date(save_path):
	# Update the last played date in the save file
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			var save_data = JSON.parse_string(json_text)
			if typeof(save_data) == TYPE_DICTIONARY:
				save_data["last_played_date"] = Time.get_datetime_string_from_system()
				
				# Write the updated data back to the file
				file = FileAccess.open(save_path, FileAccess.WRITE)
				if file:
					json_text = JSON.stringify(save_data, "  ")
					file.store_string(json_text)
					file.close()

func _update_last_connected_date(server_path):
	# Update the last connected date in the server file
	if FileAccess.file_exists(server_path):
		var file = FileAccess.open(server_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			var server_data = JSON.parse_string(json_text)
			if typeof(server_data) == TYPE_DICTIONARY:
				server_data["last_connected"] = Time.get_datetime_string_from_system()
				
				# Write the updated data back to the file
				file = FileAccess.open(server_path, FileAccess.WRITE)
				if file:
					json_text = JSON.stringify(server_data, "  ")
					file.store_string(json_text)
					file.close()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/MainMenu.tscn")
