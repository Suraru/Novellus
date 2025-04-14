extends Node

class_name GlobalFormulas

# Define age ranges for each race and lifestage
const RACE_AGE_RANGES = {
	"Human": {
		"Infant": [0, 1],
		"Toddler": [2, 5],
		"Child": [6, 12],
		"Adolescent": [13, 24],
		"Adult": [25, 40],
		"Mature": [41, 60],
		"Elderly": [61, 9999]
	},
	"Elf": {
		"Infant": [0, 3],
		"Toddler": [4, 11],
		"Child": [12, 24],
		"Adolescent": [25, 49],
		"Adult": [50, 299],
		"Mature": [300, 1199],
		"Elderly": [1200, 9999]
	},
	"Dwarf": {
		"Infant": [0, 1],
		"Toddler": [2, 3],
		"Child": [4, 8],
		"Adolescent": [9, 15],
		"Adult": [16, 149],
		"Mature": [150, 299],
		"Elderly": [300, 999]
	},
	"Giant": {
		"Infant": [0, 2],
		"Toddler": [3, 8],
		"Child": [9, 15],
		"Adolescent": [16, 30],
		"Adult": [31, 40],
		"Mature": [41, 50],
		"Elderly": [51, 999]
	},
	"Orc": {
		"Infant": [0, 0],
		"Toddler": [1, 2],
		"Child": [3, 6],
		"Adolescent": [7, 14],
		"Adult": [15, 30],
		"Mature": [31, 60],
		"Elderly": [61, 999]
	},
	"Therin": {
		"Infant": [0, 0],
		"Toddler": [1, 2],
		"Child": [3, 6],
		"Adolescent": [7, 12],
		"Adult": [13, 20],
		"Mature": [21, 30],
		"Elderly": [31, 999]
	},
	"Saurin": {
		"Infant": [0, 0],
		"Toddler": [1, 2],
		"Child": [3, 5],
		"Adolescent": [6, 6],
		"Adult": [7, 40],
		"Mature": [41, 120],
		"Elderly": [121, 999]
	},
	"Nerai": {
		"Infant": [0, 0],
		"Toddler": [1, 1],
		"Child": [2, 2],
		"Adolescent": [3, 6],
		"Adult": [7, 50],
		"Mature": [51, 100],
		"Elderly": [101, 999]
	},
	"Aetheri": {
		"Infant": [0, 1],
		"Toddler": [2, 2],
		"Child": [3, 3],
		"Adolescent": [4, 4],
		"Adult": [5, 10],
		"Mature": [11, 15],
		"Elderly": [16, 999]
	},
	"Chitari": {
		"Infant": [0, 1],
		"Toddler": [2, 3],
		"Child": [4, 4],
		"Adolescent": [5, 5],
		"Adult": [6, 8],
		"Mature": [9, 10],
		"Elderly": [11, 999]
	}
}

static func get_lifestage(race: String, age: int) -> String:
	# Normalize race name to match our dictionary keys
	var normalized_race = race.capitalize()
	
	# If race doesn't exist in our data, return Unknown
	if not RACE_AGE_RANGES.has(normalized_race):
		return "Unknown"
	
	# Check each lifestage's age range
	for lifestage in RACE_AGE_RANGES[normalized_race]:
		var range_min = RACE_AGE_RANGES[normalized_race][lifestage][0]
		var range_max = RACE_AGE_RANGES[normalized_race][lifestage][1]
		
		if age >= range_min and age <= range_max:
			return lifestage
	
	# Fallback
	return "Unknown"

static func get_adulthood_age(race: String) -> int:
	# Normalize race name to match our dictionary keys
	var normalized_race = race.capitalize()
	
	# If race doesn't exist in our data, return human adulthood as default
	if not RACE_AGE_RANGES.has(normalized_race):
		return 25  # Human adulthood starts at 25
	
	# Return the minimum age for "Adult" lifestage
	return RACE_AGE_RANGES[normalized_race]["Adult"][0]
