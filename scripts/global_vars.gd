extends Node

# Currently selected save file
var selected_save: String = ""
var selected_save_data: Dictionary = {}

# Currently selected character
var selected_character_id: String = ""

# Edit character flag
var edit_character_mode: bool = false

# Paths
const SAVES_DIR = "user://saves/"
const CHARACTERS_DIR = "user://characters/"
const SERVER_LIST_PATH = "user://server_list.json"
const CUSTOM_GENDERS_PATH = "user://custom_genders.json"

# Race data
var race_adulthood_ages = {
	"Human": 18,
	"Dwarf": 50,
	"Cyclops": 20,
	"Halfling": 20,
	"Giant": 30,
	"Gnome": 40,
	"Fey": 100,
	"Nevalim": 200,
	"Orc": 14,
	"Goblin": 12,
	"Hobgoblin": 14,
	"Ogre": 16,
	"Therin": 25,
	"Saurin": 15,
	"Nerai": 16,
	"Aetheri": 50,
	"Chitari": 10,
	"Synari": 5
}

# Lifestage ranges
var lifestage_ranges = {
	"Infant": {"min": 0, "max": 1},
	"Toddler": {"min": 1, "max": 6},
	"Child": {"min": 6, "max": 12},
	"Adolescent": {"min": 12, "max": 25},
	"Adult": {"min": 25, "max": 44},
	"Aging": {"min": 44, "max": 65},
	"Elder": {"min": 65, "max": 999}
}

# Custom genders cache
var custom_genders = {}

# Load custom genders
func load_custom_genders():
	if FileAccess.file_exists(CUSTOM_GENDERS_PATH):
		var file = FileAccess.open(CUSTOM_GENDERS_PATH, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			custom_genders = json.data
	else:
		custom_genders = {}

# Save custom genders
func save_custom_genders():
	var file = FileAccess.open(CUSTOM_GENDERS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(custom_genders, "  "))
	file.close()

# Get lifestage based on age
func get_lifestage_for_age(age: int) -> String:
	for stage in lifestage_ranges:
		var range_data = lifestage_ranges[stage]
		if age >= range_data["min"] && age < range_data["max"]:
			return stage
	
	return "Adult" # Default fallback
