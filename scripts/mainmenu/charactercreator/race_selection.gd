extends Control

@onready var background = $Characterbg

@onready var human_button = $GridContainer/Humans/HumanButton
@onready var elf_button = $GridContainer/Elves/ElfButton
@onready var dwarf_button = $GridContainer/Dwarves/DwarfButton
@onready var giant_button = $GridContainer/Cyborgs/GiantButton
@onready var orc_button = $GridContainer/Orcs/OrcButton
@onready var therin_button = $GridContainer/Therins/TherinButton
@onready var saurian_button = $GridContainer/Saurins/SaurinButton
@onready var nerai_button = $GridContainer/Nerai/NeraiButton
@onready var aetheri_button = $GridContainer/Aetheri/AetheriButton
@onready var chitari_button = $GridContainer/Chitari/ChitariButton

var selected_race = ""

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	human_button.pressed.connect(_on_human_selected)
	elf_button.pressed.connect(_on_elf_selected)
	dwarf_button.pressed.connect(_on_dwarf_selected)
	giant_button.pressed.connect(_on_giant_selected)
	orc_button.pressed.connect(_on_orc_selected)
	therin_button.pressed.connect(_on_therin_selected)
	saurian_button.pressed.connect(_on_saurin_selected)
	nerai_button.pressed.connect(_on_nerai_selected)
	aetheri_button.pressed.connect(_on_aetheri_selected)
	chitari_button.pressed.connect(_on_chitari_selected)
	$ButtonPanel/BackButton.pressed.connect(on_back_pressed)

func _on_viewport_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	var texture_size = background.texture.get_size()
	
	# Calculate scale to cover the entire viewport
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	var scale = max(scale_x, scale_y)
	
	background.scale = Vector2(scale, scale)
	
	# Center the background
	background.position = viewport_size / 2
	background.centered = true

func _on_human_selected():
	selected_race = "Human"
	_load_race_confirm_scene()

func _on_elf_selected():
	selected_race = "Elf"
	_load_race_confirm_scene()

func _on_dwarf_selected():
	selected_race = "Dwarf"
	_load_race_confirm_scene()

func _on_giant_selected():
	selected_race = "Giant"
	_load_race_confirm_scene()

func _on_orc_selected():
	selected_race = "Orc"
	_load_race_confirm_scene()

func _on_therin_selected():
	selected_race = "Therin"
	_load_race_confirm_scene()

func _on_saurin_selected():
	selected_race = "Saurin"
	_load_race_confirm_scene()

func _on_nerai_selected():
	selected_race = "Nerai"
	_load_race_confirm_scene()

func _on_aetheri_selected():
	selected_race = "Aetheri"
	_load_race_confirm_scene()

func _on_chitari_selected():
	selected_race = "Chitari"
	_load_race_confirm_scene()

func _load_race_confirm_scene():
	var file_path = GlobalState.current_character_path
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	var character_data = JSON.parse_string(json_text)
	if typeof(character_data) == TYPE_DICTIONARY:
		character_data["race"] = selected_race
		file = FileAccess.open(file_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(character_data, "\t"))  # optional indent
		file.close()
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/RaceConfirm.tscn")

func on_back_pressed():
	var file_path = GlobalState.current_character_path
	if file_path != "" and FileAccess.file_exists(file_path):
		var dir = DirAccess.open("res://characters")
		if dir:
			dir.remove(file_path)
			print("Character file deleted: " + file_path)
			GlobalState.current_character_path = ""
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/CharacterSelection.tscn")
