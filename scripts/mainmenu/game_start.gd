extends Control

# Scene paths for navigation
const MAIN_MENU_SCENE = "res://scenes/mainmenu/MainMenu.tscn"
const CHARACTER_SELECTION_SCENE = "res://scenes/mainmenu/charactercreator/CharacterSelection.tscn"

# Node references
@onready var back_button = $ButtonPanel/BackButton
@onready var save_type_tabs = $MainContainer/SaveFilesPanel/SaveTypeTabs
@onready var save_file_list = $MainContainer/SaveFilesPanel/SaveFileList
@onready var create_save_button = $MainContainer/SaveFilesPanel/SaveButtonsContainer/CreateSaveButton
@onready var delete_save_button = $MainContainer/SaveFilesPanel/SaveButtonsContainer/DeleteSaveButton
@onready var start_button = $MainContainer/SaveFilesPanel/StartButton
@onready var switch_character_button = $MainContainer/CharacterPreviewPanel/SwitchCharacterButton
@onready var server_ip_input = $MainContainer/SaveFilesPanel/MultiplayerContainer/ServerIPInput
@onready var add_server_button = $MainContainer/SaveFilesPanel/MultiplayerContainer/ServerButtonsContainer/AddServerButton
@onready var delete_server_button = $MainContainer/SaveFilesPanel/MultiplayerContainer/ServerButtonsContainer/DeleteServerButton
@onready var multiplayer_container = $MainContainer/SaveFilesPanel/MultiplayerContainer

# For character info panel
@onready var no_character_label = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/NoCharacterLabel
@onready var character_portrait = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterPortrait
@onready var character_details = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails
@onready var name_label = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/NameLabel
@onready var detail_grid = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid

# Popups
var edit_save_popup: ConfirmationDialog
var edit_save_name_line_edit: LineEdit
var delete_confirmation_popup: ConfirmationDialog

# Current state
var current_tab_index: int = 0
var selected_server_index: int = -1

# Server settings for multiplayer
var server_list: Array = []

func _ready():
	# Make sure the saves directory exists
	var dir = DirAccess.open("user://")
	if !dir.dir_exists("saves"):
		dir.make_dir("saves")
	
	# Load server list if exists
	load_server_list()
	
	# Connect tab change signal
	save_type_tabs.tab_changed.connect(_on_tab_changed)
	
	# Connect button signals
	back_button.pressed.connect(_on_back_button_pressed)
	create_save_button.pressed.connect(_on_create_save_button_pressed)
	delete_save_button.pressed.connect(_on_delete_save_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	switch_character_button.pressed.connect(_on_switch_character_button_pressed)
	add_server_button.pressed.connect(_on_add_server_button_pressed)
	delete_server_button.pressed.connect(_on_delete_server_button_pressed)
	
	# Connect list signals
	save_file_list.item_selected.connect(_on_save_file_selected)
	save_file_list.item_activated.connect(_on_save_file_activated)
	
	# Text changed for server input
	server_ip_input.text_changed.connect(_on_server_ip_changed)
	
	# Create edit save popup
	_create_edit_save_popup()
	
	# Create delete confirmation popup
	_create_delete_confirmation_popup()
	
	# Add an edit save button if it doesn't exist
	if !has_node("MainContainer/SaveFilesPanel/SaveButtonsContainer/EditSaveButton"):
		var edit_button = Button.new()
		edit_button.name = "EditSaveButton"
		edit_button.text = "Edit Save"
		edit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit_button.theme_override_font_sizes = {"font_size": 20}
		edit_button.disabled = true
		edit_button.pressed.connect(_on_edit_save_button_pressed)
		$MainContainer/SaveFilesPanel/SaveButtonsContainer.add_child(edit_button)
	else:
		var edit_button = $MainContainer/SaveFilesPanel/SaveButtonsContainer/EditSaveButton
		edit_button.pressed.connect(_on_edit_save_button_pressed)
	
	# Initial UI refresh
	_on_tab_changed(0)
	refresh_save_file_list()
	update_ui_state()

# UI Creation
func _create_edit_save_popup():
	edit_save_popup = ConfirmationDialog.new()
	edit_save_popup.title = "Edit Save Name"
	edit_save_popup.dialog_text = "Enter a new name for this save:"
	edit_save_popup.min_size = Vector2(400, 150)
	
	edit_save_name_line_edit = LineEdit.new()
	edit_save_name_line_edit.placeholder_text = "New save name"
	edit_save_name_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	margin.add_child(edit_save_name_line_edit)
	
	edit_save_popup.add_child(margin)
	edit_save_popup.confirmed.connect(_on_edit_save_confirmed)
	
	add_child(edit_save_popup)

func _create_delete_confirmation_popup():
	delete_confirmation_popup = ConfirmationDialog.new()
	delete_confirmation_popup.title = "Confirm Deletion"
	delete_confirmation_popup.dialog_text = "Are you sure you want to delete this save file? This action cannot be undone."
	delete_confirmation_popup.min_size = Vector2(400, 150)
	delete_confirmation_popup.confirmed.connect(_on_delete_save_confirmed)
	
	add_child(delete_confirmation_popup)

# Tab Switch Logic
func _on_tab_changed(tab_index: int):
	current_tab_index = tab_index
	save_file_list.clear()
	
	match tab_index:
		0: # Saved Games tab
			multiplayer_container.visible = false
			refresh_save_file_list()
			create_save_button.visible = true
			delete_save_button.visible = true
			switch_character_button.disabled = GlobalVars.selected_save.is_empty()
			
			# Show edit save button if it exists
			if has_node("MainContainer/SaveFilesPanel/SaveButtonsContainer/EditSaveButton"):
				var edit_button = $MainContainer/SaveFilesPanel/SaveButtonsContainer/EditSaveButton
				edit_button.visible = true
			
		1: # Campaigns tab
			multiplayer_container.visible = false
			refresh_campaign_list()
			create_save_button.visible = false
			delete_save_button.visible = false
			switch_character_button.disabled = true
			
			# Hide edit save button if it exists
			if has_node("MainContainer/SaveFilesPanel/SaveButtonsContainer/EditSaveButton"):
				var edit_button = $MainContainer/SaveFilesPanel/SaveButtonsContainer/EditSaveButton
				edit_button.visible = false
			
		2: # Multiplayer tab
			multiplayer_container.visible = true
			refresh_server_list()
			create_save_button.visible = false
			delete_save_button.visible = false
			switch_character_button.disabled = true
			
			# Hide edit save button if it exists
			if has_node("MainContainer/SaveFilesPanel/SaveButtonsContainer/EditSaveButton"):
				var edit_button = $MainContainer/SaveFilesPanel/SaveButtonsContainer/EditSaveButton
				edit_button.visible = false
	
	update_ui_state()

# UI Update Logic
func update_ui_state():
	var has_valid_selection = false
	
	match current_tab_index:
		0: # Saved Games
			has_valid_selection = !GlobalVars.selected_save.is_empty()
			switch_character_button.disabled = !has_valid_selection
			
		1: # Campaigns
			has_valid_selection = save_file_list.get_selected_items().size() > 0
			switch_character_button.disabled = true
			
		2: # Multiplayer
			has_valid_selection = selected_server_index >= 0 
			switch_character_button.disabled = true
			
			# Update server UI
			var has_valid_ip = _is_valid_server_address(server_ip_input.text)
			add_server_button.disabled = !has_valid_ip
			delete_server_button.disabled = selected_server_index < 0
	
	# Common button states
	delete_save_button.disabled = !has_valid_selection
	start_button.disabled = !has_valid_selection
	
	if has_node("MainContainer/SaveFilesPanel/SaveButtonsContainer/EditSaveButton"):
		var edit_button = $MainContainer/SaveFilesPanel/SaveButtonsContainer/EditSaveButton
		edit_button.disabled = !has_valid_selection || current_tab_index != 0
	
	# Update character panel
	update_character_panel()

func update_character_panel():
	var has_character = false
	
	if !GlobalVars.selected_save.is_empty():
		var save_data = GlobalVars.selected_save_data
		
		if save_data.has("CurrentCharacter") && !save_data["CurrentCharacter"].is_empty():
			has_character = true
			
			# Hide no character label, show character info
			no_character_label.visible = false
			character_portrait.visible = true
			character_details.visible = true
			
			# Load character data
			var character_data = _load_character_data(save_data["CurrentCharacter"])
			
			# Update UI with character data
			if character_data.size() > 0:
				name_label.text = character_data.get("Name", "Unknown Character")
				
				# Update stat values in the grid
				var age_value = detail_grid.get_node("AgeValue")
				var race_value = detail_grid.get_node("RaceValue")
				var gender_value = detail_grid.get_node("GenderValue")
				var lifestage_value = detail_grid.get_node("LifestageValue")
				
				age_value.text = str(character_data.get("Age", "?"))
				race_value.text = character_data.get("Race", "Unknown")
				gender_value.text = character_data.get("Gender", "Unknown")
				lifestage_value.text = character_data.get("Lifestage", "Adult")
				
				# TODO: Load character portrait if available
				# character_portrait.texture = load(character_data.get("PortraitPath", ""))
			
	if !has_character:
		# Show no character label, hide character info
		no_character_label.visible = true
		character_portrait.visible = false
		character_details.visible = false

# Save File Operations
func load_save_data(save_name: String) -> Dictionary:
	if save_name.is_empty():
		return {}
	
	var file_path = GlobalVars.SAVES_DIR + save_name
	if !FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error == OK:
		return json.data
	
	return {}

func save_save_data(save_name: String, data: Dictionary) -> bool:
	var file_path = GlobalVars.SAVES_DIR + save_name
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
	
	var json_text = JSON.stringify(data, "  ")
	file.store_string(json_text)
	file.close()
	
	return true

func delete_save_file(save_name: String) -> bool:
	var file_path = GlobalVars.SAVES_DIR + save_name
	if !FileAccess.file_exists(file_path):
		return false
	
	var dir = DirAccess.open(GlobalVars.SAVES_DIR)
	if dir.remove(save_name) == OK:
		if GlobalVars.selected_save == save_name:
			GlobalVars.selected_save = ""
			GlobalVars.selected_save_data = {}
		return true
	
	return false

# Server List Operations
func load_server_list():
	if FileAccess.file_exists(GlobalVars.SERVER_LIST_PATH):
		var file = FileAccess.open(GlobalVars.SERVER_LIST_PATH, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			server_list = json.data
	else:
		server_list = []

func save_server_list():
	var file = FileAccess.open(GlobalVars.SERVER_LIST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(server_list, "  "))
	file.close()

func add_server(server_data: Dictionary):
	server_list.append(server_data)
	save_server_list()

func remove_server(index: int):
	if index >= 0 and index < server_list.size():
		server_list.remove_at(index)
		save_server_list()

# Data Loading Functions
func refresh_save_file_list():
	save_file_list.clear()
	
	var dir = DirAccess.open(GlobalVars.SAVES_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".json"):
				var save_data = load_save_data(file_name)
				var display_name = save_data.get("Name", file_name.get_basename())
				save_file_list.add_item(display_name)
				save_file_list.set_item_metadata(save_file_list.item_count - 1, file_name)
				
				# Check if this is the currently selected save
				if file_name == GlobalVars.selected_save:
					save_file_list.select(save_file_list.item_count - 1)
			
			file_name = dir.get_next()

func refresh_campaign_list():
	# TODO: Implement this when campaign files are ready
	save_file_list.add_item("Campaigns not implemented yet")
	save_file_list.set_item_disabled(0, true)

func refresh_server_list():
	save_file_list.clear()
	
	for i in range(server_list.size()):
		var server = server_list[i]
		var server_name = server.get("name", "Unknown Server")
		var server_ip = server.get("ip", "")
		var player_count = server.get("player_count", "?")
		
		var display_text = "%s - %s (%s players)" % [server_name, server_ip, player_count]
		save_file_list.add_item(display_text)
	
	selected_server_index = -1

func _load_character_data(character_id: String) -> Dictionary:
	# TODO: Implement proper character data loading
	# This is a placeholder until the character system is implemented
	var character_file = "user://characters/%s.json" % character_id
	
	if FileAccess.file_exists(character_file):
		var file = FileAccess.open(character_file, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			return json.data
	
	# Return empty placeholder data if file doesn't exist
	return {
		"Name": character_id,
		"Age": 25,
		"Race": "Human",
		"Gender": "Male",
		"Lifestage": "Adult"
	}

# Button Handler Functions
func _on_back_button_pressed():
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_save_file_selected(index: int):
	if current_tab_index == 0: # Saved Games tab
		var file_name = save_file_list.get_item_metadata(index)
		GlobalVars.selected_save = file_name
		GlobalVars.selected_save_data = load_save_data(file_name)
	elif current_tab_index == 2: # Multiplayer tab
		selected_server_index = index
	
	update_ui_state()

func _on_save_file_activated(index: int):
	# Double-click action - typically start the game
	if !start_button.disabled:
		_on_start_button_pressed()

func _on_create_save_button_pressed():
	# Create a new save file and go to character selection
	var new_save_number = _find_next_save_number()
	var new_save_name = "World%d.json" % new_save_number
	
	# Create basic save data
	var save_data = {
		"Name": "World %d" % new_save_number,
		"CurrentCharacter": "",
		"DateCreated": Time.get_datetime_string_from_system()
	}
	
	# Save the file
	if save_save_data(new_save_name, save_data):
		GlobalVars.selected_save = new_save_name
		GlobalVars.selected_save_data = save_data
		
		# Go to character selection
		get_tree().change_scene_to_file(CHARACTER_SELECTION_SCENE)

func _on_delete_save_button_pressed():
	if current_tab_index == 0 && !GlobalVars.selected_save.is_empty():
		delete_confirmation_popup.dialog_text = "Are you sure you want to delete this save file? This action cannot be undone."
		delete_confirmation_popup.popup_centered()

func _on_delete_server_button_pressed():
	if current_tab_index == 2 && selected_server_index >= 0:
		# Show confirmation for server deletion
		delete_confirmation_popup.dialog_text = "Are you sure you want to remove this server from your list?"
		delete_confirmation_popup.popup_centered()

func _on_delete_save_confirmed():
	if current_tab_index == 0: # Saved Games tab
		delete_save_file(GlobalVars.selected_save)
		refresh_save_file_list()
	elif current_tab_index == 2: # Multiplayer tab
		remove_server(selected_server_index)
		refresh_server_list()
		selected_server_index = -1
	
	update_ui_state()

func _on_edit_save_button_pressed():
	if GlobalVars.selected_save.is_empty():
		return
	
	var save_data = GlobalVars.selected_save_data
	edit_save_name_line_edit.text = save_data.get("Name", "")
	edit_save_popup.popup_centered()

func _on_edit_save_confirmed():
	var new_name = edit_save_name_line_edit.text.strip_edges()
	if new_name.is_empty():
		return
	
	# Update save data
	if !GlobalVars.selected_save.is_empty():
		var save_data = GlobalVars.selected_save_data
		save_data["Name"] = new_name
		save_save_data(GlobalVars.selected_save, save_data)
		
		# Refresh the list
		refresh_save_file_list()

func _on_start_button_pressed():
	match current_tab_index:
		0: # Saved Games - Start the game with current save
			# TODO: Implement loading the actual game with the selected save
			print("Starting game with save: ", GlobalVars.selected_save)
			
		1: # Campaigns - Start the selected campaign
			# TODO: Implement campaign loading
			print("Starting campaign (not implemented)")
			
		2: # Multiplayer - Connect to selected server
			if selected_server_index >= 0:
				var server_data = server_list[selected_server_index]
				_connect_to_server(server_data["ip"])
	
	# For now, just go back to main menu
	# get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_switch_character_button_pressed():
	# Go to character selection screen
	get_tree().change_scene_to_file(CHARACTER_SELECTION_SCENE)

func _on_server_ip_changed(new_text: String):
	add_server_button.disabled = !_is_valid_server_address(new_text)

func _on_add_server_button_pressed():
	var server_address = server_ip_input.text.strip_edges()
	if _is_valid_server_address(server_address):
		# Try to get server info - this would typically be done with networking
		# For now, we'll just add it with placeholder data
		var server_data = {
			"name": "Server %d" % (server_list.size() + 1),
			"ip": server_address,
			"player_count": "0"
		}
		
		add_server(server_data)
		refresh_server_list()
		server_ip_input.text = ""
		
		# Select the newly added server
		if save_file_list.item_count > 0:
			save_file_list.select(save_file_list.item_count - 1)
			selected_server_index = save_file_list.item_count - 1
			update_ui_state()

# Helper Functions
func _find_next_save_number() -> int:
	var max_number = 0
	var used_numbers = []
	
	var dir = DirAccess.open(GlobalVars.SAVES_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if !dir.current_is_dir() and file_name.begins_with("World") and file_name.ends_with(".json"):
				var number_str = file_name.substr(5, file_name.length() - 10) # Remove "World" and ".json"
				if number_str.is_valid_int():
					var number = number_str.to_int()
					used_numbers.append(number)
					if number > max_number:
						max_number = number
			
			file_name = dir.get_next()
	
	# Find smallest unused number
	for i in range(1, max_number + 2):
		if !used_numbers.has(i):
			return i
	
	return max_number + 1

func _is_valid_server_address(address: String) -> bool:
	# Very basic validation - could be expanded
	if address.is_empty() || !address.contains(":"):
		return false
	
	var parts = address.split(":")
	if parts.size() != 2:
		return false
	
	var ip = parts[0]
	var port = parts[1]
	
	# Check if port is a valid number
	if !port.is_valid_int():
		return false
	
	var port_num = port.to_int()
	if port_num < 1 || port_num > 65535:
		return false
	
	# IP validation could be improved
	return true

func _connect_to_server(server_address: String):
	# TODO: Implement actual networking connection
	print("Connecting to server: ", server_address)
