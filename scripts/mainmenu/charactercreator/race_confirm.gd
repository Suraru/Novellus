extends Control

@onready var background = $Characterbg

@onready var race_description = $RaceDescription
@onready var race_image = $RaceImage

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	$ButtonPanel/StartButton.pressed.connect(on_start_pressed)
	$ButtonPanel/BackButton.pressed.connect(on_back_pressed)
	_load_selected_race_data()

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
	"Human": "res://assets/race_images/human.png",
	"Elf": "res://assets/race_images/elf.png",
	"Dwarf": "res://assets/race_images/dwarf.png",
	"Giant": "res://assets/race_images/giant.png",
	"Orc": "res://assets/race_images/orc.png",
	"Therin": "res://assets/race_images/therin.png",
	"Saurin": "res://assets/race_images/saurin.png",
	"Nerai": "res://assets/race_images/nerai.png",
	"Aetheri": "res://assets/race_images/aetheri.png",
	"Chitari": "res://assets/race_images/chitari.png"
}

var race_descriptions = {
	"Human": "Humans were the only intelligent species on earth for over a millenia, until the convergence in 2012. Once nearing extinction, humanity was able to regain supremacy thanks to their incredible ability to quickly adapt and breed. 
	
	Humans have hundreds of cultures built over thousands of years. Names vary based on cultures of old.
	Their four primary subraces include Africans, Europeans, Asians, and Americans.
	
	Humans mixed with elves produce Fey. 
	When mixed with Dwarves you get Halflings. 
	Orcish corruption creates a Hobgoblin. 
	If somehow you manage to mate with a Cyclops, you can create Giants.
	Any copulation with any of the bioengineered species will result in more human like version of those species.
	
	As a human, your stats are baseline with no increases or decreases.
	
	Your lifepsan is 60-80 years, you reach adolencence by 12 and adulthood by 25.",
	"Elf": "Elves are a rare but ancient race that are thought to be the original humanoids in the universe, where humans and dwarves are descended from. They have extremely low libido and were considered to be extinct until the convergence brought back a new population. 
	
	Elves are rare, thus their cultures are few. Names can range from plant related, to poetry, to more classical names you'd find from Tolkien.
	Their four primary subraces include High Elves, Wood Elves, Elemental Elves, and Dark Elves.
	
	Elves mixed with Humans create Fey. 
	When mixed with Dwarves you get Gnomes. 
	Orcish corruption creates full blooded Orcs. 
	You are unable to mate with Cyclops or bioengineered species due to being too different from your biology.
	
	As an elf, your long life means you can learn more, but you take longer to do it. Therefore, your intelligence is decreased.
	However, you have very high sensitivty compared to the other races, which grants you an incredibly affinity for magic.
	
	Your lifepsan is infinite, but you reach adolencence by 25 and adulthood by 50.",
	"Dwarf": "Dwarves are thought to be ancient humans who evolved on a high gravity planet.",
	"Giant": "Cyclops are very large tusked humanoids with an unknown origin. ",
	"Orc": "Orcs are a collection of corrupted beings with a history dealing with demons.",
	"Therin": "Therins are bioengineered humans that take on animalistic traits. They can range from feline, canine, vulpine, or even ursine.",
	"Saurin": "Saurins are bioengineered humans that take on reptilin traits. They can range from snakes, lizards, crocs, and turtles.",
	"Nerai": "Nerai are bioengineered humans that take on marine traits. They can range from fish, dolphins, frogs, and even whales.",
	"Aetheri": "Aetheri are bioengineered humans that take on avian traits. They can range from birds, birds, bird, and more birds.",
	"Chitari": "Chitari are bioengineered humans that were overtaken by insect traits. They can range from ants, spiders, maggots, and centipedes."
}

func _load_selected_race_data():
	var file_path = GlobalState.current_character_path
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	var json = JSON.parse_string(json_text)
	var selected_race = json["race"]
	
	if selected_race in race_images:
		race_image.texture = load(race_images[selected_race])
	if selected_race in race_descriptions:
		race_description.text = race_descriptions[selected_race]

func on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/ChangeAppearance.tscn")

func on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/RaceSelection.tscn")
