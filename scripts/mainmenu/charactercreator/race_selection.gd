extends Control

# Scene paths
const CHARACTER_SELECTION_SCENE = "res://scenes/mainmenu/charactercreator/CharacterSelection.tscn"
const CHANGE_APPEARANCE_SCENE = "res://scenes/mainmenu/charactercreator/ChangeAppearance.tscn"

# Node references
@onready var race_list_container = $MainContainer/LeftPanel/RaceListScroll/MarginContainer/RaceList
@onready var race_image = $MainContainer/RightPanel/DetailPanel/DetailContent/RaceImage
@onready var race_description = $MainContainer/RightPanel/DetailPanel/DetailContent/RaceDescription
@onready var race_title = $MainContainer/RightPanel/Header/RaceTitle
@onready var back_button = $ButtonPanel/BackButton
@onready var confirm_button = $ButtonPanel/ConfirmButton

# Race data
var race_data = {
	# Humanoid Races
	"Human": {
		"description": "Humans are versatile and adaptable, found in nearly every corner of the world. They are known for their ambition, creativity, and ability to thrive in diverse environments.",
		"image": "res://assets/race_images/human.png"
	},
	"Dwarf": {
		"description": "Dwarves are stout, hardy folk known for their craftsmanship and resilience. They excel at mining, metalworking, and have natural resistance to toxins.",
		"image": "res://assets/race_images/dwarf.png"
	},
	"Cyclops": {
		"description": "Cyclopes are large humanoids with a single eye. They possess immense strength and surprising dexterity, often working as blacksmiths or stone masons.",
		"image": "res://assets/race_images/cyclops.png"
	},
	"Halfling": {
		"description": "Halflings are small, nimble folk with a natural talent for stealth and remarkable luck. They value comfort and good food above all else.",
		"image": "res://assets/race_images/halfling.png"
	},
	"Giant": {
		"description": "Giants tower over other races, possessing incredible strength and endurance. Despite their fearsome appearance, many giants are contemplative and wise.",
		"image": "res://assets/race_images/giant.png"
	},
	"Gnome": {
		"description": "Gnomes are diminutive inventive geniuses with a natural affinity for illusion magic and mechanical contraptions. They approach life with enthusiasm and curiosity.",
		"image": "res://assets/race_images/gnome.png"
	},
	
	# Celestial Races
	"Fey": {
		"description": "Fey are ethereal beings with a deep connection to nature and magic. Their capricious nature and otherworldly beauty make them both sought after and feared.",
		"image": "res://assets/race_images/fey.png"
	},
	"Nevalim": {
		"description": "Nevalim are celestial beings of light and order. They serve as emissaries of higher powers, embodying justice and protection.",
		"image": "res://assets/race_images/nevalim.png"
	},
	"Orc": {
		"description": "Orcs are fierce warriors with impressive physical prowess. Their tribal society values strength and honor, with a rich tradition of oral history.",
		"image": "res://assets/race_images/orc.png"
	},
	"Goblin": {
		"description": "Goblins are small, clever creatures with a knack for scavenging and tinkering. Their innovative solutions often make up for their lack of physical strength.",
		"image": "res://assets/race_images/goblin.png"
	},
	"Hobgoblin": {
		"description": "Hobgoblins are disciplined and militaristic, valuing order and strategy. Their societies are highly organized with clear hierarchies and martial traditions.",
		"image": "res://assets/race_images/hobgoblin.png"
	},
	"Ogre": {
		"description": "Ogres are massive and strong, with voracious appetites. Despite their fearsome reputation, many ogres are gentle giants when treated with respect.",
		"image": "res://assets/race_images/ogre.png"
	},
	
	# Synthetic Races
	"Therin": {
		"description": "Therin are an ancient race crafted from arcane energies. Their fluid, ethereal forms allow them to manipulate elements and channel magical forces.",
		"image": "res://assets/race_images/therin.png"
	},
	"Saurin": {
		"description": "Saurin are reptilian humanoids with natural armor and keen senses. Their connection to primal forces grants them unique insights and abilities.",
		"image": "res://assets/race_images/saurin.png"
	},
	"Nerai": {
		"description": "Nerai are aquatic beings with an innate connection to water. Their societies thrive in underwater realms, with complex social structures and artistic traditions.",
		"image": "res://assets/race_images/nerai.png"
	},
	"Aetheri": {
		"description": "Aetheri are beings of pure energy, capable of manipulating the fundamental forces of the universe. Their perspective transcends physical limitations.",
		"image": "res://assets/race_images/aetheri.png"
	},
	"Chitari": {
		"description": "Chitari are insectoid beings with a hive-like mentality. Their collective intelligence and specialized physical adaptations make them formidable allies or opponents.",
		"image": "res://assets/race_images/chitari.png"
	},
	"Synari": {
		"description": "Synari are synthetic beings created through advanced alchemy and artifice. Their logical minds and customizable forms give them unique advantages.",
		"image": "res://assets/race_images/synari.png"
	}
}

# Currently selected race
var selected_race: String = ""

func _ready():
	# Connect button signals
	back_button.pressed.connect(_on_back_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	
	# Connect race button signals
	for child in race_list_container.get_children():
		if child is Button:
			child.pressed.connect(_on_race_button_pressed.bind(child.text))
	
	# Initialize UI
	confirm_button.disabled = true
	race_title.text = "Race Details"
	race_description.text = "Please select a race from the left panel to view details."
	race_image.texture = null
	
	# Check if we're editing an existing character
	if !GlobalVars.selected_character_id.is_empty():
		var character_data = load_character_data(GlobalVars.selected_character_id)
		if character_data.has("Race") && !character_data["Race"].is_empty():
			selected_race = character_data["Race"]
			# Select this race in the UI
			for child in race_list_container.get_children():
				if child is Button && child.text == selected_race:
					child.emit_signal("pressed")
					break

# Button Handlers
func _on_back_button_pressed():
	# Delete the character if we just created it
	if !GlobalVars.edit_character_mode && !GlobalVars.selected_character_id.is_empty():
		delete_character(GlobalVars.selected_character_id)
	
	# Go back to character selection
	get_tree().change_scene_to_file(CHARACTER_SELECTION_SCENE)

func _on_confirm_button_pressed():
	if !selected_race.is_empty() && !GlobalVars.selected_character_id.is_empty():
		# Update character data with selected race
		var character_data = load_character_data(GlobalVars.selected_character_id)
		character_data["Race"] = selected_race
		save_character_data(GlobalVars.selected_character_id, character_data)
		
		# Go to change appearance screen
		get_tree().change_scene_to_file(CHANGE_APPEARANCE_SCENE)

func _on_race_button_pressed(race_name: String):
	selected_race = race_name
	
	# Update UI
	race_title.text = race_name
	
	if race_data.has(race_name):
		race_description.text = race_data[race_name]["description"]
		
		# Load race image
		var image_path = race_data[race_name]["image"]
		if ResourceLoader.exists(image_path):
			race_image.texture = load(image_path)
		else:
			race_image.texture = null
	else:
		race_description.text = "No information available for this race."
		race_image.texture = null
	
	# Enable confirm button
	confirm_button.disabled = false

# Data Operations
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
		if dir.remove(character_id + ".json") == OK:
			GlobalVars.selected_character_id = ""
			return true
	
	return false
