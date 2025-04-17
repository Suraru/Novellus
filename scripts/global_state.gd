extends Node

# Constants
const SAVE_DIR = "user://saves/"
const CHARACTERS_DIR = "user://characters/"
const SETTINGS_PATH = "user://game_settings.cfg"

# Current active save file
var active_save_file: String = ""
var active_character_id: String = ""

# Game state
var is_new_game: bool = false
var is_multiplayer: bool = false
var is_campaign: bool = false
var server_address: String = ""

func _ready():
	 # Create necessary directories
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if not DirAccess.dir_exists_absolute(CHARACTERS_DIR):
		DirAccess.make_dir_recursive_absolute(CHARACTERS_DIR)
	
	# Load last active save if available
	load_settings()

func set_active_save(save_filename: String) -> void:
	active_save_file = save_filename
	
	# Reset character selection when changing saves
	active_character_id = ""
	
	# Save this setting
	save_settings()
	
	print("Active save set to: ", active_save_file)

func save_character_data(character_data: Dictionary) -> String:
	# Make sure character has an ID
	if not character_data.has("id") or character_data.id.is_empty():
		character_data["id"] = generate_unique_id()
	
	var character_id = character_data["id"]
	var character_path = CHARACTERS_DIR + character_id + ".json"
	
	# Save character to file
	var file = FileAccess.open(character_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(character_data, "\t"))
		file.close()
		print("Character saved: ", character_path)
	
	return character_id

# Add a function to load character data from a file
func load_character_data(character_id: String) -> Dictionary:
	var character_path = CHARACTERS_DIR + character_id + ".json"
	
	if FileAccess.file_exists(character_path):
		var file = FileAccess.open(character_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			var character_data = JSON.parse_string(json_text)
			if typeof(character_data) == TYPE_DICTIONARY:
				return character_data
	
	return {}

func set_active_character(character_id: String) -> void:
	active_character_id = character_id
	print("Setting active character to: " + character_id)
	
	# Update the active save file with this character ID
	var save_data = get_active_save_data()
	print("Active save file: " + active_save_file)
	print("Save data empty?: " + str(save_data.is_empty()))
	
	if !save_data.is_empty():
		save_data["active_character_id"] = character_id
		print("Updated save data with character_id: " + character_id)
		
		# Make sure the character is in the character_ids list
		if !save_data.has("character_ids"):
			save_data["character_ids"] = []
		
		if !save_data.character_ids.has(character_id):
			save_data.character_ids.append(character_id)
		
		# Save the changes
		var success = save_active_save_data(save_data)
		print("Save success: " + str(success))
	else:
		print("ERROR: Could not update save file - no active save data")
	
	save_settings()

func get_active_save_path() -> String:
	if active_save_file.is_empty():
		return ""
	
	# Make sure the path includes the directory and has a .save extension
	var filename = active_save_file
	if not filename.begins_with(SAVE_DIR):
		filename = SAVE_DIR + filename
	
	if not filename.ends_with(".save"):
		filename += ".save"
	
	return filename

func get_active_save_data() -> Dictionary:
	var save_path = get_active_save_path()
	
	if save_path.is_empty() or not FileAccess.file_exists(save_path):
		return {}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var parse_result = JSON.parse_string(json_text)
		if parse_result != null and typeof(parse_result) == TYPE_DICTIONARY:
			return parse_result
	
	return {}

func save_active_save_data(save_data: Dictionary) -> bool:
	var save_path = get_active_save_path()
	
	if save_path.is_empty():
		print("No active save file set")
		return false
	
	# Update the save's metadata
	save_data["last_played"] = Time.get_datetime_string_from_system()
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		# Use JSON.stringify with indent for human-readability
		file.store_string(JSON.stringify(save_data, "  "))
		file.close()
		print("Save data written to: ", save_path)
		return true
	
	print("Failed to write save data to: ", save_path)
	return false

func add_character_to_save(character_data: Dictionary) -> String:
	# First save the character data to its own file
	var character_id = save_character_data(character_data)
	
	# Then add the character ID to the save file
	var save_data = get_active_save_data()
	
	if save_data.is_empty():
		# Create a new save if none exists
		save_data = {
			"created_at": Time.get_datetime_string_from_system(),
			"last_played": Time.get_datetime_string_from_system(),
			"character_ids": []
		}
	
	# Update character list in save data
	if not save_data.has("character_ids"):
		save_data["character_ids"] = []
	
	if not character_id in save_data["character_ids"]:
		save_data["character_ids"].append(character_id)
	
	# Set as active character in this save
	save_data["active_character_id"] = character_id
	active_character_id = character_id
	
	# Save the data back to the file
	save_active_save_data(save_data)
	
	return character_id

func remove_character_from_save(character_id: String) -> bool:
	var save_data = get_active_save_data()
	
	if save_data.is_empty() or not save_data.has("character_ids"):
		return false
	
	if save_data.character_ids.has(character_id):
		save_data.character_ids.erase(character_id)
		
		# If this was the active character, clear it
		if active_character_id == character_id:
			active_character_id = ""
			save_data["active_character_id"] = ""
			
		# Save the updated data
		return save_active_save_data(save_data)
	
	return false

func get_active_character_data() -> Dictionary:
	if active_character_id.is_empty():
		return {}
	
	return load_character_data(active_character_id)

func delete_character(character_id: String) -> bool:
	var character_path = CHARACTERS_DIR + character_id + ".json"
	
	if FileAccess.file_exists(character_path):
		var dir = DirAccess.open(CHARACTERS_DIR)
		if dir:
			return dir.remove(character_id + ".json") == OK
	
	return false

func get_all_characters() -> Array:
	var characters = []
	
	var dir = DirAccess.open(CHARACTERS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".json"):
				var character_id = file_name.get_basename()
				var character_data = load_character_data(character_id)
				if not character_data.is_empty():
					characters.append(character_data)
			file_name = dir.get_next()
	
	return characters

func save_settings() -> void:
	var config = ConfigFile.new()
	
	# Game state settings
	config.set_value("game", "active_save_file", active_save_file)
	config.set_value("game", "active_character_id", active_character_id)
	
	# Save the configuration
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	if err == OK:
		active_save_file = config.get_value("game", "active_save_file", "")
		active_character_id = config.get_value("game", "active_character_id", "")
	else:
		active_save_file = ""
		active_character_id = ""

func generate_unique_id() -> String:
	# Generate a random unique ID
	return str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000000)

func start_new_game(save_file: String = "") -> void:
	is_new_game = true
	
	if save_file.is_empty():
		# Create a new save file with timestamp
		var timestamp = Time.get_datetime_string_from_system()
		save_file = "save_" + timestamp.replace(":", "-").replace(" ", "_")
	
	# Always ensure .save extension
	if not save_file.ends_with(".save"):
		save_file += ".save"
	
	# Extract just the filename
	save_file = save_file.get_file()
	
	# Set as active save
	set_active_save(save_file)
	
	# Create an empty save file if it doesn't exist
	var save_path = SAVE_DIR + save_file
	if not FileAccess.file_exists(save_path):
		var save_data = {
			"created_at": Time.get_datetime_string_from_system(),
			"last_played": Time.get_datetime_string_from_system(),
			"characters": []
		}
		
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		if file:
			file.store_var(save_data)
			file.close()
			print("Created new save file: ", save_path)

func start_multiplayer_game(server: String) -> void:
	is_multiplayer = true
	server_address = server
	
	# You might want to create a special multiplayer save or load existing one
	# Additional multiplayer setup here

func start_campaign_game(campaign_id: String) -> void:
	is_campaign = true
	
	# Load campaign data
	# Additional campaign setup here
