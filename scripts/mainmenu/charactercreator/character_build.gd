extends Control

@onready var background = $Characterbg

@warning_ignore("shadowed_global_identifier")
const GlobalFormulas = preload("res://scripts/global_formulas.gd")

@onready var name_input = $LeftContainer/ScrollContainer/Stats/NameFields/NameEdit
@onready var surname_input = $LeftContainer/ScrollContainer/Stats/NameFields/SurnameEdit
@onready var nickname_input = $LeftContainer/ScrollContainer/Stats/NameFields/NicknameEdit
@onready var fullname_input = $LeftContainer/ScrollContainer/Stats/NameFields/FullnameEdit
@onready var age_input = $LeftContainer/ScrollContainer/Stats/DetailTable/AgeEdit
@onready var lifestage_display = $LeftContainer/ScrollContainer/Stats/DetailTable/lifestage_display
@onready var race_display = $LeftContainer/ScrollContainer/Stats/DetailTable/race_display

@onready var gender_dropdown = $LeftContainer/ScrollContainer/Stats/DetailTable/gender_dropdown
@onready var subject_pronoun_display = $LeftContainer/ScrollContainer/Stats/DetailTable/subject_pronoun_display
@onready var object_pronoun_display = $LeftContainer/ScrollContainer/Stats/DetailTable/object_pronoun_display
@onready var custom_gender_popup = $LeftContainer/ScrollContainer/Stats/DetailTable/custom_gender_popup
@onready var custom_gender_input = $LeftContainer/ScrollContainer/Stats/DetailTable/custom_gender_popup/VBoxContainer/custom_gender_input
@onready var custom_subject_input = $LeftContainer/ScrollContainer/Stats/DetailTable/custom_gender_popup/VBoxContainer/custom_subject_input
@onready var custom_object_input = $LeftContainer/ScrollContainer/Stats/DetailTable/custom_gender_popup/VBoxContainer/custom_object_input
@onready var confirm_custom_gender_button = $LeftContainer/ScrollContainer/Stats/DetailTable/custom_gender_popup/VBoxContainer/confirm_custom_gender_button

@onready var strength_slider = $LeftContainer/ScrollContainer/Stats/AttributeTable/StrengthSlider
@onready var intelligence_slider = $LeftContainer/ScrollContainer/Stats/AttributeTable/IntelligenceSlider
@onready var endurance_slider = $LeftContainer/ScrollContainer/Stats/AttributeTable/EnduranceSlider
@onready var charisma_slider = $LeftContainer/ScrollContainer/Stats/AttributeTable/CharismaSlider

@onready var creativity_slider = $LeftContainer/ScrollContainer/Stats/PersonalityTable/CreativitySlider
@onready var extroversion_slider = $LeftContainer/ScrollContainer/Stats/PersonalityTable/ExtroversionSlider
@onready var ambition_slider = $LeftContainer/ScrollContainer/Stats/PersonalityTable/AmbitionSlider
@onready var stubbornness_slider = $LeftContainer/ScrollContainer/Stats/PersonalityTable/StubbornnessSlider

@onready var trait_popup := $LeftContainer/ScrollContainer/Stats/TraitsSection/TraitPopup
@onready var trait_list := $LeftContainer/ScrollContainer/Stats/TraitsSection/TraitPopup/ScrollContainer/TraitList
@onready var selected_traits_flow := $LeftContainer/ScrollContainer/Stats/TraitsSection/SelectedTraitsFlow
@onready var add_trait_button := $LeftContainer/ScrollContainer/Stats/TraitsSection/AddTraitButton

@onready var relationship_section = $MiddleContainer/ScrollContainer/Stats/RelationshipSection
@onready var relationship_list = relationship_section.get_node("RelationshipList")
@onready var new_relationship_button = relationship_section.get_node("NewRelationshipButton")
@onready var relationship_creator = relationship_section.get_node("RelationshipCreator")
@onready var character_selector = relationship_creator.get_node("CharacterSelector")
@onready var relationship_type_selector = relationship_creator.get_node("RelationshipTypeSelector")
@onready var confirm_button = relationship_creator.get_node("ConfirmButton")
@onready var cancel_button = relationship_creator.get_node("CancelButton")

@onready var start_button = $ButtonPanel/StartButton
@onready var back_button = $ButtonPanel/BackButton

var character_data = {}
var custom_genders: Dictionary = {}
var available_traits := {}
var selected_traits: Array = []
var relationships: Array = []
var all_characters: Array = []  # Load character list from files
var character_fullnames: Dictionary = {}  # Map of filename to fullname
var character_genders: Dictionary = {}    # Map of filename to gender
var is_fullname_manually_edited: bool = false # Track if fullname was manually edited

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	_load_character_data()
	_load_available_traits()
	_update_trait_list()
	
	gender_dropdown.clear()
	gender_dropdown.add_item("Male")
	gender_dropdown.add_item("Female")
	gender_dropdown.add_item("Nonbinary")
	gender_dropdown.add_item("Other")
	gender_dropdown.connect("item_selected", Callable(self, "_on_gender_selected"))
	confirm_custom_gender_button.connect("pressed", Callable(self, "_on_confirm_custom_gender"))

	# Connect UI signals
	if add_trait_button:
		add_trait_button.pressed.connect(_on_AddTraitButton_pressed)
	new_relationship_button.pressed.connect(_on_new_relationship_pressed)
	confirm_button.pressed.connect(_on_confirm_relationship)
	cancel_button.pressed.connect(_on_cancel_relationship)
	start_button.pressed.connect(on_start_pressed)
	back_button.pressed.connect(on_back_pressed)
	
	# Connect name and surname signals for auto-generating fullname
	name_input.text_changed.connect(_on_name_or_surname_changed)
	surname_input.text_changed.connect(_on_name_or_surname_changed)
	fullname_input.text_changed.connect(_on_fullname_changed)
	
	var character_data = GlobalState.get_active_character_data()
	if !character_data.is_empty():
		# We're editing an existing character
		back_button.disabled = true
	
	_load_existing_characters()
	_load_relationships()
	_detect_siblings()

func _on_viewport_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Handle background scaling
	var bg_texture_size = background.texture.get_size()
	var bg_scale_x = viewport_size.x / bg_texture_size.x
	var bg_scale_y = viewport_size.y / bg_texture_size.y
	var scaling_factor = max(bg_scale_x, bg_scale_y)
	
	background.scale = Vector2(scaling_factor, scaling_factor)
	background.centered = false

func _on_name_or_surname_changed(_new_text: String = ""):
	# Only update fullname if it hasn't been manually edited
	if not is_fullname_manually_edited:
		var full = name_input.text + " " + surname_input.text
		fullname_input.text = full.strip_edges()

func _on_fullname_changed(_new_text: String = ""):
	# If user manually edits fullname, mark it as manually edited
	var auto_generated = name_input.text + " " + surname_input.text
	is_fullname_manually_edited = (fullname_input.text != auto_generated && fullname_input.text != "")

func _load_available_traits():
	# Example traits - replace with your actual trait system
	available_traits = {
		"Athletic": {"description": "Character is physically fit"},
		"Intelligent": {"description": "Character has superior intellect"},
		"Charismatic": {"description": "Character has great people skills"},
		"Creative": {"description": "Character has artistic tendencies"},
		"Stubborn": {"description": "Character rarely changes their mind"}
		# Add more traits as needed
	}

func _load_character_data():
	character_data = GlobalState.get_active_character_data()
	
	if !character_data.is_empty():
		name_input.text = character_data.get("name", "")
		surname_input.text = character_data.get("surname", "")
		nickname_input.text = character_data.get("nickname", "")
		
		# Check if fullname exists in the data
		if character_data.has("fullname") and character_data["fullname"] != "":
			fullname_input.text = character_data["fullname"]
			# If fullname differs from auto-generated, mark as manually edited
			var auto_generated = name_input.text + " " + surname_input.text
			is_fullname_manually_edited = (fullname_input.text != auto_generated)
		else:
			# Auto-generate fullname if not present
			fullname_input.text = name_input.text + " " + surname_input.text
			is_fullname_manually_edited = false
		
		# Set race
		race_display.text = character_data.get("race", "Human").capitalize()
		
		# Set age or default to adulthood age for the race
		if character_data.has("age"):
			age_input.value = float(character_data["age"])
		else:
			# Get adulthood age for this race
			var adulthood_age = GlobalFormulas.get_adulthood_age(race_display.text)
			age_input.value = adulthood_age
			
		var lifestage = GlobalFormulas.get_lifestage(race_display.text, age_input.value)
		lifestage_display.text = lifestage
		
		# Load gender if it exists
		if character_data.has("gender"):
			var gender = character_data["gender"]
			_set_gender_ui(gender)
			
			# Also load pronouns if they exist
			if character_data.has("pronouns"):
				subject_pronoun_display.text = character_data["pronouns"].get("subject", "They")
				object_pronoun_display.text = character_data["pronouns"].get("object", "Them")
		
		strength_slider.value = character_data.get("strength", 3)
		intelligence_slider.value = character_data.get("intelligence", 3)
		endurance_slider.value = character_data.get("endurance", 3)
		charisma_slider.value = character_data.get("charisma", 3)

		creativity_slider.value = character_data.get("creativity", 3)
		extroversion_slider.value = character_data.get("extroversion", 3)
		ambition_slider.value = character_data.get("ambition", 3)
		stubbornness_slider.value = character_data.get("stubbornness", 3)
		
		# Load traits if they exist
		if character_data.has("traits"):
			selected_traits = character_data["traits"]
			for trait_name in selected_traits:
				_add_trait_box(trait_name)

func _set_gender_ui(gender: String):
	# Find and select the gender in the dropdown
	for i in range(gender_dropdown.get_item_count()):
		if gender_dropdown.get_item_text(i) == gender:
			gender_dropdown.select(i)
			return
	
	# If gender not found in dropdown, it might be a custom gender
	if gender != "Male" and gender != "Female" and gender != "Nonbinary":
		# Add custom gender to dropdown and select it
		if character_data.has("pronouns"):
			var subject = character_data["pronouns"].get("subject", "They")
			var object = character_data["pronouns"].get("object", "Them")
			custom_genders[gender] = {
				"subject": subject,
				"object": object
			}
			
			# Add before "Other"
			var other_index = gender_dropdown.get_item_count() - 1
			gender_dropdown.remove_item(other_index)  # Remove "Other" temporarily
			gender_dropdown.add_item(gender)
			gender_dropdown.add_item("Other")  # Re-add "Other"
			
			# Select the new custom gender
			gender_dropdown.select(gender_dropdown.get_item_count() - 2)

func _on_gender_selected(index: int):
	var gender = gender_dropdown.get_item_text(index)

	match gender:
		"Male":
			subject_pronoun_display.text = "He"
			object_pronoun_display.text = "Him"
		"Female":
			subject_pronoun_display.text = "She"
			object_pronoun_display.text = "Her"
		"Nonbinary":
			subject_pronoun_display.text = "They"
			object_pronoun_display.text = "Them"
		"Other":
			custom_gender_popup.popup_centered()
		_:
			if custom_genders.has(gender):
				subject_pronoun_display.text = custom_genders[gender]["subject"]
				object_pronoun_display.text = custom_genders[gender]["object"]

func _on_confirm_custom_gender():
	var custom_gender = custom_gender_input.text.strip_edges()
	var custom_subject = custom_subject_input.text.strip_edges()
	var custom_object = custom_object_input.text.strip_edges()

	if custom_gender != "" and custom_subject != "" and custom_object != "":
		custom_genders[custom_gender] = {
			"subject": custom_subject,
			"object": custom_object
		}
		# Add to dropdown before "Other"
		var other_index = gender_dropdown.get_item_count() - 1
		gender_dropdown.remove_item(other_index)  # Remove "Other" temporarily
		gender_dropdown.add_item(custom_gender)
		gender_dropdown.add_item("Other")  # Re-add "Other"

		# Set newly added gender
		var new_index = gender_dropdown.get_item_count() - 2
		gender_dropdown.select(new_index)
		subject_pronoun_display.text = custom_subject
		object_pronoun_display.text = custom_object
		custom_gender_popup.hide()

func _update_trait_list():
	# Clear existing list
	for child in trait_list.get_children():
		child.queue_free()

	var sorted_traits = available_traits.keys()
	sorted_traits.sort()

	for trait_name in sorted_traits:
		if trait_name in selected_traits:
			continue  # Skip already selected traits

		var button = Button.new()
		button.text = trait_name
		button.tooltip_text = available_traits[trait_name].get("description", "")
		button.connect("pressed", Callable(self, "_on_trait_selected").bind(trait_name))
		trait_list.add_child(button)

func _on_trait_selected(trait_name: String):
	if trait_name in selected_traits:
		return
	selected_traits.append(trait_name)
	_add_trait_box(trait_name)
	trait_popup.hide()

func _add_trait_box(trait_name: String):
	var panel = PanelContainer.new()
	panel.name = trait_name.replace(" ", "_")
	
	var box = HBoxContainer.new()
	
	var label = Label.new()
	label.text = trait_name
	box.add_child(label)

	var remove_btn = Button.new()
	remove_btn.text = "X"
	remove_btn.connect("pressed", Callable(self, "_on_remove_trait").bind(trait_name, panel))
	box.add_child(remove_btn)

	panel.add_child(box)
	selected_traits_flow.add_child(panel)

func _on_remove_trait(trait_name: String, box: Node):
	selected_traits.erase(trait_name)
	selected_traits_flow.remove_child(box)
	box.queue_free()

func _on_AddTraitButton_pressed():
	_update_trait_list()
	trait_popup.popup_centered()

func meets_prerequisites(trait_data: Dictionary, stats: Dictionary) -> bool:
	for key in trait_data.get("prerequisites", {}).keys():
		if !stats.has(key) or stats[key] < trait_data["prerequisites"][key]:
			return false
	return true

func _load_existing_characters():
	all_characters = []
	character_fullnames = {}
	character_genders = {}
	
	character_selector.clear()
	character_selector.add_item("Random")
	
	# Get all characters from the save file
	var save_data = GlobalState.get_active_save_data()
	if !save_data.is_empty() and save_data.has("characters"):
		for character in save_data.characters:
			if character.has("id"):
				var char_id = character.id
				all_characters.append(char_id)
				
				var fullname = character.get("fullname", "")
				if fullname == "":
					fullname = character.get("name", "") + " " + character.get("surname", "")
				
				character_fullnames[char_id] = fullname.strip_edges()
				character_genders[char_id] = character.get("gender", "")
				
				# Add to selector with the fullname for display
				character_selector.add_item(fullname.strip_edges())

func _load_relationships():
	if character_data.has("relationships"):
		relationships = character_data["relationships"]
	else:
		relationships = []
	_update_relationship_list()

func _get_gender_term(gender: String, role: String) -> String:
	match role:
		"Parent":
			match gender:
				"Male": return "Father"
				"Female": return "Mother"
				_: return "Parent"
		"Child":
			match gender:
				"Male": return "Son"
				"Female": return "Daughter"
				_: return "Child"
		"Sibling":
			match gender:
				"Male": return "Brother"
				"Female": return "Sister"
				_: return "Sibling"
		_:
			return role

func _update_relationship_list():
	# Manually remove all existing children
	for child in relationship_list.get_children():
		child.queue_free()

	# Add a new container for each relationship
	for i in range(relationships.size()):
		var rel = relationships[i]
		var container = HBoxContainer.new()
		
		var label = Label.new()
		
		# Get proper full name for the character
		var character_identifier = rel["character"]
		var display_name = character_identifier
		
		if character_identifier != "Random" and character_fullnames.has(character_identifier):
			display_name = character_fullnames[character_identifier]
		
		# Get gender-appropriate role name
		var role_type = rel["type"]
		if role_type != "Random" and character_identifier != "Random":
			var gender = character_genders.get(character_identifier, "")
			if role_type == "Parent" or role_type == "Child" or role_type == "Sibling":
				role_type = _get_gender_term(gender, role_type)
		
		label.text = "%s: %s" % [role_type, display_name]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(label)
		
		# Add delete button
		var remove_btn = Button.new()
		remove_btn.text = "X"
		remove_btn.connect("pressed", Callable(self, "_on_remove_relationship").bind(i))
		container.add_child(remove_btn)
		
		relationship_list.add_child(container)

func _on_remove_relationship(index: int):
	if index >= 0 and index < relationships.size():
		relationships.remove_at(index)
		character_data["relationships"] = relationships
		_update_relationship_list()

func _detect_siblings():
	# Find all characters that share the same parent
	var parent_to_children = {}
	
	# Get current save data to find all characters
	var save_data = GlobalState.get_active_save_data()
	if save_data.is_empty() or not save_data.has("characters"):
		return
	
	# First, build a mapping of parents to their children
	for character in save_data.characters:
		if character.has("relationships"):
			for rel in character["relationships"]:
				if rel["type"] == "Parent" or rel["type"] == "Father" or rel["type"] == "Mother":
					var parent_id = rel["character"]
					if !parent_to_children.has(parent_id):
						parent_to_children[parent_id] = []
					parent_to_children[parent_id].append(character.id)
	
	# Find current character's parents
	var my_parents = []
	var my_char_id = GlobalState.active_character_id
	
	for rel in relationships:
		if rel["type"] == "Parent" or rel["type"] == "Father" or rel["type"] == "Mother":
			my_parents.append(rel["character"])
	
	# Add sibling relationships for characters that share parents with this character
	for parent in my_parents:
		if parent_to_children.has(parent):
			for child_id in parent_to_children[parent]:
				if child_id != my_char_id:
					# Check if this sibling already exists in relationships
					var sibling_exists = false
					for rel in relationships:
						if (rel["type"] == "Sibling" or rel["type"] == "Brother" or rel["type"] == "Sister") and rel["character"] == child_id:
							sibling_exists = true
							break
					
					if !sibling_exists:
						# Find the gender of this child from the save data
						var sibling_gender = ""
						for character in save_data.characters:
							if character.id == child_id:
								sibling_gender = character.get("gender", "")
								break
						
						var relationship_type = _get_gender_term(sibling_gender, "Sibling")
						
						var new_relationship = {
							"character": child_id,
							"type": relationship_type
						}
						relationships.append(new_relationship)
	
	# Update the relationships in character_data
	if relationships.size() > 0:
		character_data["relationships"] = relationships
		_update_relationship_list()

func _on_new_relationship_pressed():
	relationship_creator.visible = true
	new_relationship_button.visible = false
	relationship_type_selector.clear()
	relationship_type_selector.add_item("Random")
	relationship_type_selector.add_item("Parent")
	relationship_type_selector.add_item("Child")
	relationship_type_selector.add_item("Best Friend")
	relationship_type_selector.add_item("Friend")
	relationship_type_selector.add_item("Enemy")
	relationship_type_selector.add_item("Nemesis")
	relationship_type_selector.add_item("Adoptive Parent")
	relationship_type_selector.add_item("Adoptive Child")

func _on_cancel_relationship():
	relationship_creator.visible = false
	new_relationship_button.visible = true

func _on_confirm_relationship():
	var selected_character := ""
	var selected_index = character_selector.get_selected_id()
	
	if selected_index == 0:
		selected_character = "Random"
	else:
		# Get the actual filename, not the displayed text
		var selected_fullname = character_selector.get_item_text(selected_index)
		
		# Find the character identifier that matches this fullname
		for char_name in character_fullnames.keys():
			if character_fullnames[char_name] == selected_fullname:
				selected_character = char_name
				break
		
		# Fallback if not found
		if selected_character == "":
			selected_character = selected_fullname

	var selected_type := ""
	var type_index = relationship_type_selector.get_selected_id()
	
	if type_index == 0:
		selected_type = "Random"
	else:
		selected_type = relationship_type_selector.get_item_text(type_index)
		
		# Convert to gender-specific term if needed
		if selected_type in ["Parent", "Child", "Sibling"] and selected_character != "Random":
			var gender = character_genders.get(selected_character, "")
			selected_type = _get_gender_term(gender, selected_type)

	var new_relationship = {
		"character": selected_character,
		"type": selected_type
	}

	relationships.append(new_relationship)
	character_data["relationships"] = relationships
	relationship_creator.visible = false
	new_relationship_button.visible = true
	_update_relationship_list()
	
	# If we just added a parent relationship, detect siblings
	if selected_type.begins_with("Parent") or selected_type == "Father" or selected_type == "Mother":
		_detect_siblings()

func on_start_pressed():
	character_data["name"] = name_input.text
	character_data["surname"] = surname_input.text
	character_data["nickname"] = nickname_input.text
	character_data["fullname"] = fullname_input.text
	character_data["age"] = age_input.value
	
	# Save gender and pronouns
	var selected_index = gender_dropdown.get_selected_id()
	var gender = gender_dropdown.get_item_text(selected_index)
	character_data["gender"] = gender
	
	character_data["pronouns"] = {
		"subject": subject_pronoun_display.text,
		"object": object_pronoun_display.text
	}
	
	character_data["strength"] = strength_slider.value
	character_data["intelligence"] = intelligence_slider.value
	character_data["endurance"] = endurance_slider.value
	character_data["charisma"] = charisma_slider.value

	character_data["creativity"] = creativity_slider.value
	character_data["extroversion"] = extroversion_slider.value
	character_data["ambition"] = ambition_slider.value
	character_data["stubbornness"] = stubbornness_slider.value
	
	# Save traits
	character_data["traits"] = selected_traits
	
	# Save to the active save file
	GlobalState.add_character_to_save(character_data)
	
	# Proceed to next step or go back to main character screen
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/CharacterSelection.tscn")

func on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/ChangeAppearance.tscn")

func _on_age_edit_value_changed(value: float) -> void:
	var race = character_data.get("race", "Human")
	var lifestage = GlobalFormulas.get_lifestage(race, int(value))
	lifestage_display.text = lifestage
