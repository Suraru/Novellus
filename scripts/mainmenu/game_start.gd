extends Control

@onready var background = $Characterbg
@onready var save_file_list = $MainContainer/SaveFilesPanel/SaveFileList
@onready var switch_character_button = $MainContainer/CharacterPreviewPanel/SwitchCharacterButton  # Renamed
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
@onready var save_type_tabs = $MainContainer/SaveFilesPanel/SaveTypeTabs  # New tabbed container

# Enum for file types to improve code readability
enum FileType { CAMPAIGN, SAVE_FILE }

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

func _ready():
	# Ensure we have all the UI elements before connecting signals
	if save_file_list:
		save_file_list.item_selected.connect(_on_save_selected)
	else:
		push_error("SaveFileList not found in GameStart scene")
	
	if switch_character_button:
		switch_character_button.pressed.connect(_on_choose_character_pressed)
	else:
		push_error("ChooseCharacterButton not found in GameStart scene")
	
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
	
	# Make sure background is appropriately sized
	_on_viewport_size_changed()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Load save files
	_load_files()

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
	
	var current_tab = 0  # Default to save files tab
	if save_type_tabs:
		current_tab = save_type_tabs.current_tab
	
	# First load campaigns if on campaign tab (0)
	if current_tab == 1:
		_load_campaign_files()
	# Load save files if on saves tab (1)
	else:
		_load_save_files()
	
	# Handle empty list
	if save_files.size() == 0:
		var message = "No campaigns available yet." if current_tab == 0 else "No saved games found."
		save_file_list.add_item(message)
		save_file_list.set_item_disabled(0, true)
		save_file_list.select(0)

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

func _load_save_files():
	# Load character files from the characters directory
	var dir_path = "res://characters"
	
	# Check if characters directory exists
	if not DirAccess.dir_exists_absolute(dir_path):
		print("Characters directory does not exist yet. No saves to load.")
		return
	
	var dir = DirAccess.open(dir_path)
	if not dir:
		print("Failed to open characters directory: ", dir_path)
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
						var save_data = SaveData.new(
							file_path,
							json,
							FileType.SAVE_FILE
						)
						save_files.append(save_data)
						
						var label = "%s | Age: %s | Race: %s" % [
							json.get("fullname", "Unknown"),
							str(json.get("age", "??")),
							json.get("race", "Unknown")
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
	
	# Update preview based on file type
	if selected_save.type == FileType.CAMPAIGN:
		_show_campaign_preview(selected_save.data)
	else:
		_show_character_preview(selected_save.data)
	
	# Enable start button
	if start_button:
		start_button.disabled = false
	
	if Engine.has_singleton("GlobalState"):
		GlobalState.current_character_path = selected_file_path

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

func _show_character_preview(character_data):
	# Update UI for character preview - check for null references
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
	
	# Calculate lifestage - only if the required elements exist
	if lifestage_value:
		var race = character_data.get("race", "Human")
		var age = int(character_data.get("age", 25))
		var lifestage = "Adult"  # Default in case GlobalFormulas not available
		
		# Check if GlobalFormulas class exists
		if ClassDB.class_exists("GlobalFormulas") or ("GlobalFormulas" in get_script().get_script_constant_map()):
			lifestage = GlobalFormulas.get_lifestage(race, age)
		
		lifestage_value.text = lifestage

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

func _on_choose_character_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/CharacterSelection.tscn")

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
	
	if selected_save.type == FileType.CAMPAIGN:
		# Load campaign scene
		print("Starting campaign: " + selected_file_path)
		# Store campaign path in GlobalState if it exists
		if Engine.has_singleton("GlobalState"):
			# Check if property exists or add it
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
	else:
		# Load sandbox mode with character
		print("Starting sandbox with character: " + selected_file_path)
		get_tree().change_scene_to_file("res://scenes/SandboxWorld.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/MainMenu.tscn")
