extends Control

@onready var background = $Characterbg

# Race buttons
@onready var race_list = $MainContainer/LeftPanel/RaceListScroll/MarginContainer/RaceList

# Detail panel elements
@onready var race_title = $MainContainer/RightPanel/Header/RaceTitle
@onready var race_image = $MainContainer/RightPanel/DetailPanel/DetailContent/RaceImage
@onready var race_description = $MainContainer/RightPanel/DetailPanel/DetailContent/RaceDescription
@onready var confirm_button = $ButtonPanel/ConfirmButton

var selected_race = ""

# Define race categories and the races within them
var race_categories = {
	"Humanoid": ["Human", "Elf", "Dwarf", "Halfling", "Gnome", "Cyclops", "Giant"],
	"Celestial": ["Fey", "Nevalim", "Orc", "Goblin", "Hobgoblin", "Ogre", "Golem"],
	"Synthetic": ["Therin", "Saurin", "Nerai", "Aetheri", "Chitari", "Synari"]
}

# Map button node name to race name
var button_to_race = {
	"Human": "Human",
	"Elf": "Elf",
	"Dwarf": "Dwarf",
	"Halfling": "Halfling",
	"Gnome": "Gnome",
	"Cyclops": "Cyclops",
	"Giant": "Giant",
	"Fey": "Fey",
	"Nevalim": "Nevalim",
	"Orc": "Orc",
	"Goblin": "Goblin",
	"Hobgoblin": "Hobgoblin",
	"Ogre": "Ogre",
	"Golem": "Golem",
	"Therin": "Therin",
	"Saurin": "Saurin",
	"Nerai": "Nerai",
	"Aetheri": "Aetheri",
	"Chitari": "Chitari",
	"Synari": "Synari"
}

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	
	# Connect race buttons
	_connect_race_buttons()
	
	# Connect navigation buttons
	$ButtonPanel/BackButton.pressed.connect(on_back_pressed)
	confirm_button.pressed.connect(on_confirm_pressed)
	
	# Initially disable confirm button until race is selected
	confirm_button.disabled = true

func _connect_race_buttons():
	# Connect all race buttons to their respective handlers
	for button in race_list.get_children():
		if button is Button:
			var race_name = button_to_race.get(button.name, "")
			if race_name != "":
				button.pressed.connect(func(): _on_race_selected(race_name))

func _on_viewport_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Handle background scaling
	var bg_texture_size = background.texture.get_size()
	var bg_scale_x = viewport_size.x / bg_texture_size.x
	var bg_scale_y = viewport_size.y / bg_texture_size.y
	var scaling_factor = max(bg_scale_x, bg_scale_y)
	
	background.scale = Vector2(scaling_factor, scaling_factor)
	background.centered = false

var race_images = {
	"Human": "res://assets/icons/races/humans.png",
	"Elf": "res://assets/icons/races/elves.png",
	"Dwarf": "res://assets/icons/races/dwarves.png",
	"Cyclops": "res://assets/icons/races/cyborgs.png",
	"Giant": "res://assets/icons/races/cyborgs.png",
	"Orc": "res://assets/icons/races/orcs.png",
	"Goblin": "res://assets/icons/races/orcs.png",
	"Hobgoblin": "res://assets/icons/races/orcs.png",
	"Therin": "res://assets/icons/races/therins.png",
	"Saurin": "res://assets/icons/races/saurins.png",
	"Nerai": "res://assets/icons/races/netai.png",
	"Aetheri": "res://assets/icons/races/aetheri.png",
	"Chitari": "res://assets/icons/races/chitari.png"
	# Add the rest of your race images here
}

var race_descriptions = {
	"Human": "Humans are the result of breeding between Cyclops and Dwarves. They were left on earth and became the dominant species after a few generations of evolution bottlenecked them into a single intelligent species. As magic dwindled in the 17th century following the execution of the final celestial races, they experienced a technological leap and dominated their planet alone until the Convergence in late 2012. 

	Once nearing extinction, humanity was able to regain supremacy thanks to their incredible ability to quickly adapt and breed. While their population hasn’t had the chance to reach the same heights they did 300 years ago, they have at least become a much more unified people. Although you can still find humans who try to hold onto their ancient history and cultures, of which there were once thousands. 

	Their four primary subraces include: Africans, Europeans, Asians, and Americans. There is little to no difference between them besides physical appearance.
	
	As a human, your stats are baseline with no increases or decreases.
	
	Your lifespan is 60-80 years, you reach adolescence by 12 and adulthood by 25.",
	
	"Elf": "Elves are the result of breeding between Fey and Humans. They appear largely similar to humans, but with pointed ears. Being a half-breed, their culture tends to match that of their parent’s, with most defaulting to human-like cultures, with sometimes a bit of Fey culture mixed in.

	Elves began to raise in popularity after Fey interference began on Earth, however by the 17th century they were all killed off due to their aptitude for magic. While there were still some humans with some fey DNA, they were too diluted to be considered Elves. Now with the return of the Fey in 2012, Elves have found themselves back on the rise, although amongst strong resentment from the humans trying to preserve their species. 

	Their four primary subraces are the same as Fey, being: High Elves, Wood Elves, Dark Elves, Elemental Elves. However unlike Fey, your skin color will match that of your human parent. 

	As an Elf, you have a slight reduction to your intelligence thanks to your Fey ancestry, but your longer life makes up for it. You are also slightly more magically attuned, making you a bit more sensitive on average compared to humans. 
	
	Unlike pureblood Fey, your life span is not infinite, but you do age slower than humans, at least physically. You can easily live over 100 if you’re careful, but you’re a late bloomer, reaching adolescence by 14, and generally not being fully developed until 30. ",

	"Dwarf": "Dwarves were created by Celestials to act as servants to the Fey. They live primarily on high gravity worlds, but have been known to be moved to mine other planets. This has resulted in a grudge against Fey, and by extension Elves, Gnomes, and Golems, stronger than their grudge against Demonkind, such as Orcs, Goblins, and Ogres. 

	Many Dwarves have broken free of their shackles and have created highly socialized communes, taking the means of production into their own hands, at the cost of their individuality. Despite that, many of these communes have become incredibly wealthy. However, not all Dwarves are part of these communes, and others have gone off on their own to create their own living with their hard work.

	 Dwarves have four primary subraces. Ground Dwarves, Mountain Dwarves, Core Dwarves, and Space Dwarves. 

	Ground Dwarves live on the surface and specialize in tasks such as woodcutting, fishing, farming, or hunting. Their skin tends to appear similar to that of humans, ranging from peachy to darker tones. 

	Mountain Dwarves make their living inside mountains, thus tend to appear as pale or gray. They specialize in forging, mining, construction, and have excellent dark vision, but struggle in high lit areas.

	Core Dwarves are reddish in color and have high heat resistance, thus can be found just outside of the mantle of most planets. Lime Mountains Dwarves, they also specialize in forging, mining, and construction, but struggle to see in the dark. 

	Space Dwarves are blue in color, and can survive prolonged exposure to space. While they still need oxygen to function, they are incredibly strong and radiation resistant. Their main specialization is mining asteroids.

	Dwarves can live past 300 if they weren’t always putting stress on their body, so the average lifespan is half that unless you take on a different lifestyle. However, you do grow up faster, reaching adolescence by 8 and adulthood by 16. ",

	"Cyclops": "Cyclops are very large tusked humanoids with single eyes, made by Demonkind to spite the Celestials.",
	"Giant": "Giants are enormous humanoids, made from the unholy combination with Humans and Cyclops.",
	"Gnome": "Gnomes are small, ingenious creatures with a natural talent for technology and magic. They are the children of Dwarves and Fey, but can also appear if you mix Halflings and Elves.",
	"Fey": "Fey are the products of pure Celestials creating life. They are the closest you can get to godhood while still being constrained by mortality.",
	"Nevalim": "Nevalim are the products of pure Demons creating life. However they have freewill and often don’t associate with their creators. Despite that, they are outcasts due to their connection to the infernal. Their offspring are also cursed to create orc-like abominations.",
	"Orc": "Orcs are fey who have been corrupted into demonish creatures. To mate with them would be as if mating with Nevalim themselves.",
	"Goblin": "Goblins are small, cunning creatures known for their mischievous nature. They are the creation of Orcs or Nevalim with Dwarves, Halflings, or Gnomes.",
	"Hobgoblin": "Hobgoblins are the result of humans or elves, with Orcs or Nevalim ancestry, combining traits of both races.",
	"Ogre": "Ogres are large, powerful beings known for their incredible strength and endurance. They are the result of Orcs or Nevalim mating with Cyclops, Ogres, or Golems.",
	"Golem": "Golems are the result of Cyclops or Giants mating with Fey or Elves.",
	"Therin": "Therins are bioengineered humans that take on animalistic traits. They can range from feline, canine, vulpine, or even ursine.",
	"Saurin": "Saurins are bioengineered humans that take on reptilin traits. They can range from snakes, lizards, crocs, and turtles.",
	"Nerai": "Nerai are bioengineered humans that take on marine traits. They can range from fish, dolphins, frogs, and even whales.",
	"Aetheri": "Aetheri are bioengineered humans that take on avian traits. They can range from birds, birds, bird, and more birds.",
	"Chitari": "Chitari are bioengineered humans that were overtaken by insect traits. They can range from ants, spiders, maggots, and centipedes.",
	"Synari": "Synari are the newest synthetic race, combining elements of advanced AI with biological components."
}

func _on_race_selected(race):
	selected_race = race
	race_title.text = race
	
	# Update race image
	if race in race_images:
		race_image.texture = load(race_images[race])
	else:
		# Use a placeholder image if specific race image not found
		race_image.texture = null
		
	# Update race description
	if race in race_descriptions:
		race_description.text = race_descriptions[race]
	else:
		race_description.text = "Description for " + race + " coming soon."
	
	# Enable confirm button now that a race is selected
	confirm_button.disabled = false
	
	# Highlight the selected race button
	_highlight_selected_race(race)

func _highlight_selected_race(race):
	# Reset all buttons to normal state
	for button in race_list.get_children():
		if button is Button:
			button.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Find and highlight the selected button
	for button in race_list.get_children():
		if button is Button and button.name == race:
			button.add_theme_color_override("font_color", Color(1, 0.7, 0.2))

func on_confirm_pressed():
	_save_selected_race()
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/ChangeAppearance.tscn")

func _save_selected_race():
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

func on_back_pressed():
	var file_path = GlobalState.current_character_path
	if file_path != "" and FileAccess.file_exists(file_path):
		var dir = DirAccess.open("res://characters")
		if dir:
			dir.remove(file_path)
			print("Character file deleted: " + file_path)
			GlobalState.current_character_path = ""
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/CharacterSelection.tscn")
