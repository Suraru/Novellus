extends Control

# Scene paths
const CHANGE_APPEARANCE_SCENE = "res://scenes/mainmenu/charactercreator/ChangeAppearance.tscn"
const CHARACTER_SELECTION_SCENE = "res://scenes/mainmenu/charactercreator/CharacterSelection.tscn"

# Node references - Name and basic details
@onready var fullname_edit = $LeftContainer/ScrollContainer/Stats/NameFields/FullnameEdit
@onready var name_edit = $LeftContainer/ScrollContainer/Stats/NameFields/NameEdit
@onready var surname_edit = $LeftContainer/ScrollContainer/Stats/NameFields/SurnameEdit
@onready var nickname_edit = $LeftContainer/ScrollContainer/Stats/NameFields/NicknameEdit

@onready var age_edit = $LeftContainer/ScrollContainer/Stats/DetailTable/AgeEdit
@onready var lifestage_display = $LeftContainer/ScrollContainer/Stats/DetailTable/lifestage_display
@onready var race_display = $LeftContainer/ScrollContainer/Stats/DetailTable/race_display
@onready var gender_dropdown = $LeftContainer/ScrollContainer/Stats/DetailTable/gender_dropdown

# Pronouns display
@onready var subject_pronoun_display = $LeftContainer/ScrollContainer/Stats/DetailTable/subject_pronoun_display
@onready var object_pronoun_display = $LeftContainer/ScrollContainer/Stats/DetailTable/object_pronoun_display

# Custom gender popup
@onready var custom_gender_popup = $LeftContainer/ScrollContainer/Stats/DetailTable/custom_gender_popup
@onready var custom_gender_input = $LeftContainer/ScrollContainer/Stats/DetailTable/custom_gender_popup/VBoxContainer/custom_gender_input
@onready var custom_subject_input = $LeftContainer/ScrollContainer/Stats/DetailTable/custom_gender_popup/VBoxContainer/custom_subject_input
@onready var custom_object_input = $LeftContainer/ScrollContainer/Stats/DetailTable/custom_gender_popup/VBoxContainer/custom_object_input
@onready var confirm_custom_gender_button = $LeftContainer/ScrollContainer/Stats/DetailTable/custom_gender_popup/VBoxContainer/confirm_custom_gender_button

# Attributes
@onready var strength_slider = $LeftContainer/ScrollContainer/Stats/AttributeTable/StrengthSlider
@onready var intelligence_slider = $LeftContainer/ScrollContainer/Stats/AttributeTable/IntelligenceSlider
@onready var endurance_slider = $LeftContainer/ScrollContainer/Stats/AttributeTable/EnduranceSlider
@onready var charisma_slider = $LeftContainer/ScrollContainer/Stats/AttributeTable/CharismaSlider

# Personality
@onready var creativity_slider = $LeftContainer/ScrollContainer/Stats/PersonalityTable/CreativitySlider
@onready var extroversion_slider = $LeftContainer/ScrollContainer/Stats/PersonalityTable/ExtroversionSlider
@onready var ambition_slider = $LeftContainer/ScrollContainer/Stats/PersonalityTable/AmbitionSlider
@onready var stubbornness_slider = $LeftContainer/ScrollContainer/Stats/PersonalityTable/StubbornnessSlider

# Relationship section
@onready var relationship_list = $MiddleContainer/ScrollContainer/Stats/RelationshipSection/RelationshipList
@onready var relationship_creator = $MiddleContainer/ScrollContainer/Stats/RelationshipSection/RelationshipCreator
@onready var character_selector = $MiddleContainer/ScrollContainer/Stats/RelationshipSection/RelationshipCreator/CharacterSelector
@onready var relationship_type_selector = $MiddleContainer/ScrollContainer/Stats/RelationshipSection/RelationshipCreator/RelationshipTypeSelector
@onready var confirm_relationship_button = $MiddleContainer/ScrollContainer/Stats/RelationshipSection/RelationshipCreator/ConfirmButton
@onready var cancel_relationship_button = $MiddleContainer/ScrollContainer/Stats/RelationshipSection/RelationshipCreator/CancelButton
@onready var new_relationship_button = $MiddleContainer/ScrollContainer/Stats/RelationshipSection/NewRelationshipButton

# Bottom buttons
@onready var back_button = $ButtonPanel/BackButton
@onready var start_button = $ButtonPanel/StartButton

# Character data
var character_data = {}
var ignore_fullname_update = false
var all_characters = {}
var relationship_data = {}

func _ready():
	# Load custom genders
	GlobalVars.load_custom_genders()
	
	# Connect signals
	back_button.pressed.connect(_on_back_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	
	# Name field connections
	name_edit.text_changed.connect(_on_name_changed)
	surname_edit.text_changed.connect(_on_surname_changed)
	fullname_edit.text_changed.connect(_on_fullname_changed)
	
	# Age field connection
	# age_edit.value_changed.connect(_on_age_edit_value_changed)
	
	# Setup gender dropdown
	_setup_gender_dropdown()
	gender_dropdown.item_selected.connect(_on_gender_selected)
	
	# Connect custom gender popup
	confirm_custom_gender_button.pressed.connect(_on_confirm_custom_gender)
	
	# Connect relationship buttons
	new_relationship_button.pressed.connect(_on_new_relationship_button_pressed)
	confirm_relationship_button.pressed.connect(_on_confirm_relationship_button_pressed)
	cancel_relationship_button.pressed.connect(_on_cancel_relationship_button_pressed)
	
	# Load character data
	if !GlobalVars.selected_character_id.is_empty():
		character_data = load_character_data(GlobalVars.selected_character_id)
		_populate_ui_from_character_data()
	else:
		# Should not happen, but handle it gracefully
		character_data = _create_default_character_data()
	
	# Load all characters for relationship handling
	load_all_characters()
	
	# Initialize relationship UI
	relationship_creator.visible = false
	_populate_relationship_list()

# Setup functions
func _setup_gender_dropdown():
	gender_dropdown.clear()
	gender_dropdown.add_item("Male")
	gender_dropdown.add_item("Female")
	gender_dropdown.add_item("Nonbinary")
	gender_dropdown.add_item("Other...")
	
	# Add any custom genders from the global cache
	for gender_name in GlobalVars.custom_genders:
		if gender_name != "Male" && gender_name != "Female" && gender_name != "Nonbinary":
			gender_dropdown.add_item(gender_name)

func _populate_ui_from_character_data():
	# Populate name fields
	name_edit.text = character_data.get("Name", "")
	surname_edit.text = character_data.get("Surname", "")
	nickname_edit.text = character_data.get("Nickname", "")
	
	# Handle fullname
	var stored_fullname = character_data.get("FullName", "")
	var computed_fullname = "%s %s" % [name_edit.text, surname_edit.text]
	
	if stored_fullname.is_empty() || stored_fullname == computed_fullname:
		fullname_edit.text = computed_fullname
	else:
		fullname_edit.text = stored_fullname
	
	# Populate race
	race_display.text = character_data.get("Race", "")
	
	# Set age
	var age = character_data.get("Age", 25)
	age_edit.value = age
	_update_lifestage(age)
	
	# Set gender
	var gender = character_data.get("Gender", "Male")
	var found = false
	
	for i in range(gender_dropdown.item_count):
		if gender_dropdown.get_item_text(i) == gender:
			gender_dropdown.select(i)
			found = true
			break
	
	if !found && gender != "":
		# It's a custom gender not in the list
		gender_dropdown.add_item(gender)
		gender_dropdown.select(gender_dropdown.item_count - 1)
	
	# Update pronouns
	_update_pronouns(gender)
	
	# Set attribute values
	strength_slider.value = character_data.get("Attributes", {}).get("Strength", 3)
	intelligence_slider.value = character_data.get("Attributes", {}).get("Intelligence", 3)
	endurance_slider.value = character_data.get("Attributes", {}).get("Endurance", 3)
	charisma_slider.value = character_data.get("Attributes", {}).get("Charisma", 3)
	
	# Set personality values
	creativity_slider.value = character_data.get("Personality", {}).get("Creativity", 3)
	extroversion_slider.value = character_data.get("Personality", {}).get("Extroversion", 3)
	ambition_slider.value = character_data.get("Personality", {}).get("Ambition", 3)
	stubbornness_slider.value = character_data.get("Personality", {}).get("Stubbornness", 3)

func _create_default_character_data() -> Dictionary:
	return {
		"Name": "",
		"Surname": "",
		"FullName": "",
		"Nickname": "",
		"Age": 25,
		"Gender": "Male",
		"Race": "",
		"Attributes": {
			"Strength": 3,
			"Intelligence": 3,
			"Endurance": 3,
			"Charisma": 3
		},
		"Personality": {
			"Creativity": 3,
			"Extroversion": 3,
			"Ambition": 3,
			"Stubbornness": 3
		},
		"Relationships": {},
		"Memories": []
	}

# Data handling functions
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
	
	return _create_default_character_data()

func save_character_data(character_id: String, data: Dictionary) -> bool:
	var file_path = GlobalVars.CHARACTERS_DIR + character_id + ".json"
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
	
	var json_text = JSON.stringify(data, "  ")
	file.store_string(json_text)
	file.close()
	
	return true

func load_all_characters():
	all_characters.clear()
	
	var dir = DirAccess.open(GlobalVars.CHARACTERS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".json"):
				var character_id = file_name.get_basename()
				
				# Skip the current character
				if character_id != GlobalVars.selected_character_id:
					var char_data = load_character_data(character_id)
					all_characters[character_id] = char_data
			
			file_name = dir.get_next()
	
	# Update character selector
	_update_character_selector()

# UI update functions
func _update_lifestage(age: int):
	var lifestage = GlobalVars.get_lifestage_for_age(age)
	lifestage_display.text = lifestage
	character_data["Lifestage"] = lifestage

func _update_pronouns(gender: String):
	var subject = "They"
	var object = "Them"
	
	if gender == "Male":
		subject = "He"
		object = "Him"
	elif gender == "Female":
		subject = "She"
		object = "Her"
	elif GlobalVars.custom_genders.has(gender):
		var gender_data = GlobalVars.custom_genders[gender]
		subject = gender_data.get("subject", "They")
		object = gender_data.get("object", "Them")
	
	subject_pronoun_display.text = subject
	object_pronoun_display.text = object
	
	# Save to character data
	character_data["Pronouns"] = {
		"Subject": subject,
		"Object": object
	}

func _update_character_selector():
	character_selector.clear()
	
	for character_id in all_characters:
		var char_data = all_characters[character_id]
		var display_name = char_data.get("FullName", "")
		
		if display_name.is_empty():
			display_name = "%s %s" % [char_data.get("Name", ""), char_data.get("Surname", "")]
			if display_name.strip_edges() == "":
				display_name = "Unnamed Character"
		
		character_selector.add_item(display_name)
		character_selector.set_item_metadata(character_selector.item_count - 1, character_id)

func _setup_relationship_type_selector():
	relationship_type_selector.clear()
	relationship_type_selector.add_item("Parent")
	relationship_type_selector.add_item("Child")
	relationship_type_selector.add_item("Adoptive Parent")
	relationship_type_selector.add_item("Adoptive Child")

func _populate_relationship_list():
	# Clear existing relationships
	for child in relationship_list.get_children():
		child.queue_free()
	
	# Get relationships from character data
	var relationships = character_data.get("Relationships", {})
	
	# Create UI elements for each relationship
	for character_id in relationships:
		var relation_type = relationships[character_id]
		
		if all_characters.has(character_id):
			var related_char = all_characters[character_id]
			
			# Create relationship display
			var hbox = HBoxContainer.new()
			
			var relation_label = Label.new()
			var char_name = related_char.get("FullName", "")
			if char_name.is_empty():
				char_name = "%s %s" % [related_char.get("Name", ""), related_char.get("Surname", "")]
				if char_name.strip_edges() == "":
					char_name = "Unnamed Character"
			
			relation_label.text = "%s: %s" % [relation_type, char_name]
			relation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var delete_button = Button.new()
			delete_button.text = "X"
			delete_button.pressed.connect(_on_delete_relationship_pressed.bind(character_id))
			
			hbox.add_child(relation_label)
			hbox.add_child(delete_button)
			
			relationship_list.add_child(hbox)

# Signal handlers for name fields
func _on_name_changed(new_text: String):
	character_data["Name"] = new_text
	
	# Update fullname if not manually edited
	if !ignore_fullname_update:
		fullname_edit.text = "%s %s" % [new_text, surname_edit.text]

func _on_surname_changed(new_text: String):
	character_data["Surname"] = new_text
	
	# Update fullname if not manually edited
	if !ignore_fullname_update:
		fullname_edit.text = "%s %s" % [name_edit.text, new_text]

func _on_fullname_changed(new_text: String):
	# Flag to track if fullname is being manually edited
	if new_text != "%s %s" % [name_edit.text, surname_edit.text]:
		ignore_fullname_update = true
	else:
		ignore_fullname_update = false
	
	character_data["FullName"] = new_text

func _on_age_edit_value_changed(value: float):
	character_data["Age"] = int(value)
	_update_lifestage(int(value))

func _on_gender_selected(index: int):
	var gender = gender_dropdown.get_item_text(index)
	
	if gender == "Other...":
		# Show custom gender popup
		custom_gender_input.text = ""
		custom_subject_input.text = ""
		custom_object_input.text = ""
		custom_gender_popup.popup_centered()
	else:
		character_data["Gender"] = gender
		_update_pronouns(gender)

func _on_confirm_custom_gender():
	var gender = custom_gender_input.text.strip_edges()
	var subject = custom_subject_input.text.strip_edges()
	var object = custom_object_input.text.strip_edges()
	
	if gender.is_empty():
		return
	
	if subject.is_empty():
		subject = "They"
	
	if object.is_empty():
		object = "Them"
	
	# Save custom gender
	GlobalVars.custom_genders[gender] = {
		"subject": subject,
		"object": object
	}
	GlobalVars.save_custom_genders()
	
	# Update dropdown
	var found = false
	for i in range(gender_dropdown.item_count):
		if gender_dropdown.get_item_text(i) == gender:
			gender_dropdown.select(i)
			found = true
			break
	
	if !found:
		gender_dropdown.add_item(gender)
		gender_dropdown.select(gender_dropdown.item_count - 1)
	
	# Update character data
	character_data["Gender"] = gender
	_update_pronouns(gender)
	
	# Close popup
	custom_gender_popup.hide()

# Relationship handling
func _on_new_relationship_button_pressed():
	relationship_creator.visible = true
	_update_character_selector()
	_setup_relationship_type_selector()

func _on_cancel_relationship_button_pressed():
	relationship_creator.visible = false

func _on_confirm_relationship_button_pressed():
	if character_selector.selected < 0:
		return
	
	var selected_character_id = character_selector.get_item_metadata(character_selector.selected)
	var relation_type = relationship_type_selector.get_item_text(relationship_type_selector.selected)
	
	if selected_character_id.is_empty():
		relationship_creator.visible = false
		return
	
	# Get the selected character data
	var related_char_data = all_characters[selected_character_id]
	
	# Determine the gender-specific relationship term
	if relation_type == "Parent" || relation_type == "Adoptive Parent":
		var gender = related_char_data.get("Gender", "")
		if gender == "Male":
			relation_type = relation_type.replace("Parent", "Father")
		elif gender == "Female":
			relation_type = relation_type.replace("Parent", "Mother")
	elif relation_type == "Child" || relation_type == "Adoptive Child":
		var gender = related_char_data.get("Gender", "")
		if gender == "Male":
			relation_type = relation_type.replace("Child", "Son")
		elif gender == "Female":
			relation_type = relation_type.replace("Child", "Daughter")
	
	# Add relationship to current character
	if !character_data.has("Relationships"):
		character_data["Relationships"] = {}
	
	character_data["Relationships"][selected_character_id] = relation_type
	
	# Add reciprocal relationship to the related character
	if !related_char_data.has("Relationships"):
		related_char_data["Relationships"] = {}
	
	var reciprocal_type = _get_reciprocal_relationship(relation_type)
	
	# Determine gender-specific term for reciprocal relationship
	if reciprocal_type == "Parent" || reciprocal_type == "Adoptive Parent":
		var gender = character_data.get("Gender", "")
		if gender == "Male":
			reciprocal_type = reciprocal_type.replace("Parent", "Father")
		elif gender == "Female":
			reciprocal_type = reciprocal_type.replace("Parent", "Mother")
	elif reciprocal_type == "Child" || reciprocal_type == "Adoptive Child":
		var gender = character_data.get("Gender", "")
		if gender == "Male":
			reciprocal_type = reciprocal_type.replace("Child", "Son")
		elif gender == "Female":
			reciprocal_type = reciprocal_type.replace("Child", "Daughter")
	
	related_char_data["Relationships"][GlobalVars.selected_character_id] = reciprocal_type
	
	# Save the related character
	save_character_data(selected_character_id, related_char_data)
	
	# Find and add extended family relationships
	_process_extended_family(selected_character_id, relation_type)
	
	# Update UI
	_populate_relationship_list()
	relationship_creator.visible = false

func _on_delete_relationship_pressed(character_id: String):
	if character_data.has("Relationships") && character_data["Relationships"].has(character_id):
		# Remove relationship from current character
		character_data["Relationships"].erase(character_id)
		
		# Remove relationship from related character
		if all_characters.has(character_id):
			var related_char_data = all_characters[character_id]
			if related_char_data.has("Relationships") && related_char_data["Relationships"].has(GlobalVars.selected_character_id):
				related_char_data["Relationships"].erase(GlobalVars.selected_character_id)
				save_character_data(character_id, related_char_data)
		
		# Update UI
		_populate_relationship_list()

func _get_reciprocal_relationship(relation_type: String) -> String:
	if relation_type.contains("Father") || relation_type.contains("Mother") || relation_type.contains("Parent"):
		return relation_type.replace("Father", "Child").replace("Mother", "Child").replace("Parent", "Child")
	elif relation_type.contains("Son") || relation_type.contains("Daughter") || relation_type.contains("Child"):
		return relation_type.replace("Son", "Parent").replace("Daughter", "Parent").replace("Child", "Parent")
	
	return relation_type

func _process_extended_family(direct_relation_id: String, relation_type: String):
	# This is a simplification - a full implementation would be more complex
	# Here we just add siblings, grandparents/grandchildren, aunts/uncles/nieces/nephews
	
	var direct_relation_data = all_characters[direct_relation_id]
	var direct_relationships = direct_relation_data.get("Relationships", {})
	
	# Process based on relationship type
	if relation_type.contains("Father") || relation_type.contains("Mother") || relation_type.contains("Parent"):
		# This character is a child of direct_relation_id
		
		# Find siblings (other children of the parent)
		for sibling_id in direct_relationships:
			if sibling_id != GlobalVars.selected_character_id && direct_relationships[sibling_id].contains("Child"):
				if all_characters.has(sibling_id):
					var sibling_data = all_characters[sibling_id]
					
					# Skip if already related
					if character_data.get("Relationships", {}).has(sibling_id):
						continue
					
					# Add sibling relationship
					var sibling_type = "Sibling"
					if sibling_data.get("Gender", "") == "Male":
						sibling_type = "Brother"
					elif sibling_data.get("Gender", "") == "Female":
						sibling_type = "Sister"
					
					# Add to current character
					character_data["Relationships"][sibling_id] = sibling_type
					
					# Add to sibling
					if !sibling_data.has("Relationships"):
						sibling_data["Relationships"] = {}
					
					var reciprocal_sibling_type = "Sibling"
					if character_data.get("Gender", "") == "Male":
						reciprocal_sibling_type = "Brother"
					elif character_data.get("Gender", "") == "Female":
						reciprocal_sibling_type = "Sister"
					
					sibling_data["Relationships"][GlobalVars.selected_character_id] = reciprocal_sibling_type
					save_character_data(sibling_id, sibling_data)
		
		for other_child_id in direct_relationships:
			if other_child_id != GlobalVars.selected_character_id && direct_relationships[other_child_id].contains("Child"):
				if all_characters.has(other_child_id):
					var other_child_data = all_characters[other_child_id]
					
					# Skip if already related
					if other_child_data.get("Relationships", {}).has(GlobalVars.selected_character_id):
						continue
					
					# Add sibling relationship
					var sibling_type = "Sibling"
					if character_data.get("Gender", "") == "Male":
						sibling_type = "Brother"
					elif character_data.get("Gender", "") == "Female":
						sibling_type = "Sister"
					
					# Add to other child
					if !other_child_data.has("Relationships"):
						other_child_data["Relationships"] = {}
					
					other_child_data["Relationships"][GlobalVars.selected_character_id] = sibling_type
					save_character_data(other_child_id, other_child_data)
		
		# Find grandparents (parents of the parent)
		for grandparent_id in direct_relationships:
			if direct_relationships[grandparent_id].contains("Parent"):
				if all_characters.has(grandparent_id):
					var grandparent_data = all_characters[grandparent_id]
					
					# Skip if already related
					if character_data.get("Relationships", {}).has(grandparent_id):
						continue
					
					# Add grandparent relationship
					var grandparent_type = "Grandparent"
					if grandparent_data.get("Gender", "") == "Male":
						grandparent_type = "Grandfather"
					elif grandparent_data.get("Gender", "") == "Female":
						grandparent_type = "Grandmother"
					
					# Add to current character
					character_data["Relationships"][grandparent_id] = grandparent_type
					
					# Add to grandparent
					if !grandparent_data.has("Relationships"):
						grandparent_data["Relationships"] = {}
					
					var reciprocal_type = "Grandchild"
					if character_data.get("Gender", "") == "Male":
						reciprocal_type = "Grandson"
					elif character_data.get("Gender", "") == "Female":
						reciprocal_type = "Granddaughter"
					
					grandparent_data["Relationships"][GlobalVars.selected_character_id] = reciprocal_type
					save_character_data(grandparent_id, grandparent_data)
					
					# Find parent's siblings (aunts/uncles)
					for aunt_uncle_id in grandparent_data.get("Relationships", {}):
						if aunt_uncle_id != direct_relation_id && grandparent_data["Relationships"][aunt_uncle_id].contains("Child"):
							if all_characters.has(aunt_uncle_id):
								var aunt_uncle_data = all_characters[aunt_uncle_id]
								
								# Skip if already related
								if character_data.get("Relationships", {}).has(aunt_uncle_id):
									continue
								
								# Add aunt/uncle relationship
								var aunt_uncle_type = "Pibling" # Gender-neutral term for parent's sibling
								if aunt_uncle_data.get("Gender", "") == "Male":
									aunt_uncle_type = "Uncle"
								elif aunt_uncle_data.get("Gender", "") == "Female":
									aunt_uncle_type = "Aunt"
								
								# Add to current character
								character_data["Relationships"][aunt_uncle_id] = aunt_uncle_type
								
								# Add to aunt/uncle
								if !aunt_uncle_data.has("Relationships"):
									aunt_uncle_data["Relationships"] = {}
								
								var nibling_type = "Nibling" # Gender-neutral term for sibling's child
								if character_data.get("Gender", "") == "Male":
									nibling_type = "Nephew"
								elif character_data.get("Gender", "") == "Female":
									nibling_type = "Niece"
								
								aunt_uncle_data["Relationships"][GlobalVars.selected_character_id] = nibling_type
								save_character_data(aunt_uncle_id, aunt_uncle_data)
								
								# Find cousins (children of aunts/uncles)
								for cousin_id in aunt_uncle_data.get("Relationships", {}):
									if aunt_uncle_data["Relationships"][cousin_id].contains("Child"):
										if all_characters.has(cousin_id):
											var cousin_data = all_characters[cousin_id]
											
											# Skip if already related
											if character_data.get("Relationships", {}).has(cousin_id):
												continue
											
											# Add cousin relationship (remains "Cousin" regardless of gender)
											character_data["Relationships"][cousin_id] = "Cousin"
											
											# Add reciprocal relationship
											if !cousin_data.has("Relationships"):
												cousin_data["Relationships"] = {}
											
											cousin_data["Relationships"][GlobalVars.selected_character_id] = "Cousin"
											save_character_data(cousin_id, cousin_data)
	
	elif relation_type.contains("Son") || relation_type.contains("Daughter") || relation_type.contains("Child"):
		# This character is a parent of direct_relation_id
		
		# Find the child's children (grandchildren)
		for grandchild_id in direct_relationships:
			if direct_relationships[grandchild_id].contains("Child"):
				if all_characters.has(grandchild_id):
					var grandchild_data = all_characters[grandchild_id]
					
					# Skip if already related
					if character_data.get("Relationships", {}).has(grandchild_id):
						continue
					
					# Add grandchild relationship
					var grandchild_type = "Grandchild"
					if grandchild_data.get("Gender", "") == "Male":
						grandchild_type = "Grandson"
					elif grandchild_data.get("Gender", "") == "Female":
						grandchild_type = "Granddaughter"
					
					# Add to current character
					character_data["Relationships"][grandchild_id] = grandchild_type
					
					# Add to grandchild
					if !grandchild_data.has("Relationships"):
						grandchild_data["Relationships"] = {}
					
					var reciprocal_type = "Grandparent"
					if character_data.get("Gender", "") == "Male":
						reciprocal_type = "Grandfather"
					elif character_data.get("Gender", "") == "Female":
						reciprocal_type = "Grandmother"
					
					grandchild_data["Relationships"][GlobalVars.selected_character_id] = reciprocal_type
					save_character_data(grandchild_id, grandchild_data)
		
		# Find the child's other parents (partners/spouses)
		for partner_id in direct_relationships:
			if direct_relationships[partner_id].contains("Parent") && partner_id != GlobalVars.selected_character_id:
				if all_characters.has(partner_id):
					var partner_data = all_characters[partner_id]
					
					# Skip if already related
					if character_data.get("Relationships", {}).has(partner_id):
						continue
					
					# Add partner relationship (co-parent)
					character_data["Relationships"][partner_id] = "Co-Parent"
					
					# Add to partner
					if !partner_data.has("Relationships"):
						partner_data["Relationships"] = {}
					
					partner_data["Relationships"][GlobalVars.selected_character_id] = "Co-Parent"
					save_character_data(partner_id, partner_data)

func _on_back_button_pressed():
	get_tree().change_scene_to_file(CHANGE_APPEARANCE_SCENE)

func _on_start_button_pressed():
	# Update character attributes
	character_data["Attributes"] = {
		"Strength": strength_slider.value,
		"Intelligence": intelligence_slider.value,
		"Endurance": endurance_slider.value,
		"Charisma": charisma_slider.value
	}
	
	# Update personality
	character_data["Personality"] = {
		"Creativity": creativity_slider.value,
		"Extroversion": extroversion_slider.value,
		"Ambition": ambition_slider.value,
		"Stubbornness": stubbornness_slider.value
	}
	
	# Save the character data
	save_character_data(GlobalVars.selected_character_id, character_data)
	
	# Reset edit mode flag
	GlobalVars.edit_character_mode = false
	
	# Return to character selection
	get_tree().change_scene_to_file(CHARACTER_SELECTION_SCENE)
